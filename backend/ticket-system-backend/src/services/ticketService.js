const Ticket = require("../models/Ticket");
const Agent = require("../models/Agent");
const Notification = require("../models/Notification");
const mongoose = require("mongoose");
const { EventEmitter } = require("events");

class TicketEvents extends EventEmitter {}
const ticketEvents = new TicketEvents();

class TicketService {
	constructor() {
		this.setupEventListeners();
	}

	setupEventListeners() {
		ticketEvents.on("ticket:created", this.handleTicketCreated.bind(this));
		ticketEvents.on("ticket:assigned", this.handleTicketAssigned.bind(this));
		ticketEvents.on("ticket:updated", this.handleTicketUpdated.bind(this));
		ticketEvents.on("sla:breach", this.handleSLABreach.bind(this));
	}

	async createTicket(ticketData) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const ticket = new Ticket({
				...ticketData,
				history: [
					{
						action: "created",
						performedBy: ticketData.createdBy,
						details: { initialStatus: "queued" },
					},
				],
			});

			await ticket.save({ session });

			if (ticketData.assignedTo) {
				await this.assignTicket(ticket._id, ticketData.assignedTo, session);
			} else {
				await this.attemptAutoAssignment(ticket, session);
			}

			await session.commitTransaction();
			ticketEvents.emit("ticket:created", ticket);

			return ticket;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async attemptAutoAssignment(ticket, session) {
		const suitableAgent = await this.findOptimalAgent(ticket);
		if (suitableAgent) {
			await this.assignTicket(ticket._id, suitableAgent._id, session);
			return suitableAgent;
		}
		return null;
	}

	async findOptimalAgent(ticket) {
		const now = new Date();
		const requiredSkills = ticket.requiredSkills || [];

		// Complex query to find the best available agent
		const agents = await Agent.aggregate([
			{
				$match: {
					status: "online",
					currentLoad: { $lt: 8 },
					"shift.end": {
						$gt: new Date(
							now.getTime() + ticket.estimatedHours * 60 * 60 * 1000
						),
					},
					currentTicket: null,
					department: ticket.department,
					"skills.name": { $all: requiredSkills.map((skill) => skill.name) },
				},
			},
			{
				$addFields: {
					skillMatch: {
						$size: {
							$setIntersection: [
								"$skills.name",
								requiredSkills.map((skill) => skill.name),
							],
						},
					},
					loadScore: { $subtract: [8, "$currentLoad"] },
					experienceScore: "$performance.slaComplianceRate",
				},
			},
			{
				$addFields: {
					totalScore: {
						$add: [
							{ $multiply: ["$skillMatch", 2] },
							"$loadScore",
							{ $multiply: ["$experienceScore", 1.5] },
						],
					},
				},
			},
			{ $sort: { totalScore: -1 } },
			{ $limit: 1 },
		]);

		return agents[0];
	}

	async assignTicket(ticketId, agentId, session) {
		const [ticket, agent] = await Promise.all([
			Ticket.findById(ticketId).session(session),
			Agent.findById(agentId).session(session),
		]);

		if (!ticket || !agent) {
			throw new Error("Ticket or agent not found");
		}

		if (!agent.canHandleTicket(ticket)) {
			throw new Error("Agent cannot handle this ticket");
		}

		ticket.assignedTo = agent._id;
		ticket.status = "assigned";
		ticket.history.push({
			action: "assigned",
			performedBy: agent._id,
			details: { agentId: agent._id },
		});

		agent.currentTicket = ticket._id;
		agent.currentLoad += ticket.estimatedHours;
		agent.activeTickets.push(ticket._id);

		await Promise.all([ticket.save({ session }), agent.save({ session })]);

		ticketEvents.emit("ticket:assigned", { ticket, agent });

		return { ticket, agent };
	}

	async processQueue() {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const queuedTickets = await Ticket.find({
				status: "queued",
				assignedTo: null,
			}).sort({ priority: 1, createdAt: 1 });

			const results = {
				processed: 0,
				assigned: 0,
				failed: 0,
				escalated: 0,
			};

			for (const ticket of queuedTickets) {
				results.processed++;
				try {
					if (ticket.needsEscalation()) {
						await this.escalateTicket(ticket._id, session);
						results.escalated++;
						continue;
					}

					const agent = await this.attemptAutoAssignment(ticket, session);
					if (agent) {
						results.assigned++;
					}
				} catch (error) {
					results.failed++;
					console.error(`Failed to process ticket ${ticket._id}:`, error);
				}
			}

			await session.commitTransaction();
			return results;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async escalateTicket(ticketId, session) {
		const ticket = await Ticket.findById(ticketId).session(session);
		if (!ticket) {
			throw new Error("Ticket not found");
		}

		ticket.escalationLevel += 1;
		ticket.status = "escalated";
		ticket.history.push({
			action: "escalated",
			details: {
				reason: "SLA breach",
				previousLevel: ticket.escalationLevel - 1,
			},
		});

		// Notify supervisors and managers
		await this.notifyEscalation(ticket, session);

		// Try to find a senior agent
		const seniorAgent = await this.findSeniorAgent(ticket, session);
		if (seniorAgent) {
			await this.assignTicket(ticket._id, seniorAgent._id, session);
		}

		await ticket.save({ session });
		ticketEvents.emit("ticket:escalated", ticket);
	}

	async notifyEscalation(ticket, session) {
		const notification = new Notification({
			type: "escalation",
			ticket: ticket._id,
			priority: ticket.priority,
			message: `Ticket #${ticket._id} has been escalated to level ${ticket.escalationLevel}`,
			recipients: await this.getEscalationRecipients(ticket.department),
		});

		await notification.save({ session });
	}

	async findSeniorAgent(ticket, session) {
		return await Agent.findOne({
			department: ticket.department,
			"skills.level": { $gte: 4 },
			status: "online",
			currentLoad: { $lt: 5 },
		}).session(session);
	}

	async getEscalationRecipients(department) {
		const supervisors = await User.find({
			role: { $in: ["supervisor", "manager"] },
			department,
		}).select("_id");
		return supervisors.map((s) => s._id);
	}

	async handleSLABreach(ticket) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			await this.escalateTicket(ticket._id, session);
			await this.sendSLABreachNotifications(ticket, session);

			await session.commitTransaction();
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async handleTicketCreated(ticket) {
		// Schedule SLA checks
		this.scheduleSLACheck(ticket);
	}

	async handleTicketAssigned(data) {
		const { ticket, agent } = data;
		await this.setupSLAMonitoring(ticket);
		await this.notifyAssignment(ticket, agent);
	}

	async handleTicketUpdated(ticket) {
		await this.checkAndUpdateSLA(ticket);
	}

	scheduleSLACheck(ticket) {
		// Schedule response time check
		setTimeout(async () => {
			await this.checkResponseSLA(ticket._id);
		}, ticket.sla.responseTime.deadline - Date.now());

		// Schedule resolution time check
		setTimeout(async () => {
			await this.checkResolutionSLA(ticket._id);
		}, ticket.sla.resolutionTime.deadline - Date.now());
	}

	async checkResponseSLA(ticketId) {
		const ticket = await Ticket.findById(ticketId);
		if (!ticket || ticket.sla.responseTime.met) return;

		if (new Date() > ticket.sla.responseTime.deadline) {
			ticketEvents.emit("sla:breach", ticket);
		}
	}

	async checkResolutionSLA(ticketId) {
		const ticket = await Ticket.findById(ticketId);
		if (!ticket || ticket.status === "resolved" || ticket.status === "closed")
			return;

		if (new Date() > ticket.sla.resolutionTime.deadline) {
			ticketEvents.emit("sla:breach", ticket);
		}
	}

	async updateTicketStatus(ticketId, newStatus, userId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const ticket = await Ticket.findById(ticketId).session(session);
			if (!ticket) {
				throw new Error("Ticket not found");
			}

			const oldStatus = ticket.status;
			ticket.status = newStatus;
			ticket.history.push({
				action: "status_updated",
				performedBy: userId,
				details: { oldStatus, newStatus },
			});

			if (newStatus === "resolved") {
				ticket.sla.resolutionTime.met = true;
				await this.handleTicketResolution(ticket, session);
			}

			await ticket.save({ session });
			await session.commitTransaction();

			ticketEvents.emit("ticket:updated", ticket);
			return ticket;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async handleTicketResolution(ticket, session) {
		if (ticket.assignedTo) {
			const agent = await Agent.findById(ticket.assignedTo).session(session);
			if (agent) {
				// Update agent performance metrics
				agent.performance.ticketsResolved += 1;
				agent.currentLoad = Math.max(
					0,
					agent.currentLoad - ticket.estimatedHours
				);
				agent.activeTickets = agent.activeTickets.filter(
					(t) => t.toString() !== ticket._id.toString()
				);

				if (ticket._id.equals(agent.currentTicket)) {
					agent.currentTicket = null;
				}

				await agent.save({ session });
			}
		}
	}

	async getTicketMetrics(startDate, endDate) {
		return await Ticket.aggregate([
			{
				$match: {
					createdAt: { $gte: startDate, $lte: endDate },
				},
			},
			{
				$group: {
					_id: null,
					totalTickets: { $sum: 1 },
					resolvedTickets: {
						$sum: {
							$cond: [{ $in: ["$status", ["resolved", "closed"]] }, 1, 0],
						},
					},
					averageResolutionTime: { $avg: "$resolutionTime" },
					slaBreaches: {
						$sum: {
							$cond: [
								{
									$or: [
										{ $gt: [new Date(), "$sla.responseTime.deadline"] },
										{ $gt: [new Date(), "$sla.resolutionTime.deadline"] },
									],
								},
								1,
								0,
							],
						},
					},
				},
			},
		]);
	}
}

module.exports = new TicketService();
