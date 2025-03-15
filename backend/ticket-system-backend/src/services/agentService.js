const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");
const Notification = require("../models/Notification");
const { EventEmitter } = require("events");

class AgentEvents extends EventEmitter {}
const agentEvents = new AgentEvents();

class AgentService {
	constructor() {
		this.events = new AgentEvents();
		this.setupEventListeners();
	}

	setupEventListeners() {
		this.events.on("agent:status_changed", this.handleAgentStatusChange);
		this.events.on("agent:shift_started", this.handleShiftStart);
		this.events.on("agent:shift_ending", this.handleShiftEnding);
	}

	handleAgentStatusChange = async (data) => {
		const { agent, oldStatus } = data;
		if (oldStatus === "online" && agent.status === "offline") {
			await this.handleAgentOffline(agent);
		}
	};

	handleShiftStart = async (agent) => {
		// Schedule shift end notification
		this.scheduleShiftEndNotification(agent);
	};

	handleShiftEnding = async (agent) => {
		await this.handleAgentShiftEnd(agent);
	};

	async updateAgentStatus(agentId, status) {
		try {
			const agent = await Agent.findById(agentId);
			if (!agent) {
				throw new Error("Agent not found");
			}

			const oldStatus = agent.status;
			agent.status = status;

			// If agent goes offline, handle their current tickets
			if (status === "offline" && agent.activeTickets.length > 0) {
				await this.handleAgentOffline(agent);
			}

			await agent.save();

			agentEvents.emit("agent:status_changed", { agent, oldStatus });
			return agent;
		} catch (error) {
			console.error("Error updating agent status:", error);
			throw error;
		}
	}

	async handleAgentOffline(agent) {
		// Reassign or queue current tickets
		const tickets = await Ticket.find({
			_id: { $in: agent.activeTickets },
		});

		for (const ticket of tickets) {
			ticket.status = "queued";
			ticket.assignedTo = null;
			ticket.history.push({
				action: "reassigned",
				details: { reason: "agent_offline", previousAgent: agent._id },
			});
			await ticket.save();
		}

		agent.currentTicket = null;
		agent.activeTickets = [];
		agent.currentLoad = 0;
		await agent.save();
	}

	async startAgentShift(agentId) {
		try {
			const agent = await Agent.findById(agentId);
			if (!agent) {
				throw new Error("Agent not found");
			}

			agent.status = "online";
			agent.shift.start = new Date();
			agent.shift.end = new Date(Date.now() + 8 * 60 * 60 * 1000); // 8-hour shift

			await agent.save();

			agentEvents.emit("agent:shift_started", agent);

			// Schedule shift end notification
			this.scheduleShiftEndNotification(agent);

			return agent;
		} catch (error) {
			console.error("Error starting agent shift:", error);
			throw error;
		}
	}

	scheduleShiftEndNotification(agent) {
		const timeUntilEnd = agent.shift.end - Date.now() - 30 * 60 * 1000; // 30 minutes before shift ends
		setTimeout(() => {
			agentEvents.emit("agent:shift_ending", agent);
		}, timeUntilEnd);
	}

	async handleShiftEnding(agent) {
		// Notify agent about shift ending
		await this.createNotification({
			type: "shift_ending",
			recipient: agent._id,
			message: "Your shift ends in 30 minutes. Please prepare for handover.",
		});

		// Check for ongoing tickets
		if (agent.activeTickets.length > 0) {
			await this.initiateTicketHandover(agent);
		}
	}

	async initiateTicketHandover(agent) {
		try {
			const tickets = await Ticket.find({
				_id: { $in: agent.activeTickets },
			});

			// Find available agents for handover
			const availableAgents = await this.findHandoverAgents(agent.department);

			for (const ticket of tickets) {
				const targetAgent = this.selectHandoverAgent(availableAgents, ticket);
				if (targetAgent) {
					await this.handoverTicket(ticket, agent, targetAgent);
				}
			}
		} catch (error) {
			console.error("Error initiating ticket handover:", error);
			throw error;
		}
	}

	async handoverTicket(ticket, fromAgent, toAgent) {
		ticket.assignedTo = toAgent._id;
		ticket.history.push({
			action: "handover",
			details: {
				fromAgent: fromAgent._id,
				toAgent: toAgent._id,
				reason: "shift_ending",
			},
		});

		toAgent.activeTickets.push(ticket._id);
		toAgent.currentLoad += ticket.estimatedHours;

		fromAgent.activeTickets = fromAgent.activeTickets.filter(
			(t) => t.toString() !== ticket._id.toString()
		);
		fromAgent.currentLoad = Math.max(
			0,
			fromAgent.currentLoad - ticket.estimatedHours
		);

		await Promise.all([ticket.save(), toAgent.save(), fromAgent.save()]);

		// Notify both agents
		await this.createHandoverNotifications(ticket, fromAgent, toAgent);
	}

	async findHandoverAgents(department) {
		const now = new Date();
		return await Agent.find({
			department,
			status: "online",
			currentLoad: { $lt: 8 },
			"shift.end": { $gt: new Date(now.getTime() + 2 * 60 * 60 * 1000) }, // At least 2 hours left in shift
		}).sort("currentLoad");
	}

	selectHandoverAgent(availableAgents, ticket) {
		return availableAgents.find((agent) => agent.canHandleTicket(ticket));
	}

	async createHandoverNotifications(ticket, fromAgent, toAgent) {
		const notifications = [
			{
				type: "handover_from",
				recipient: fromAgent._id,
				message: `Ticket #${ticket._id} has been handed over to ${toAgent.name}`,
			},
			{
				type: "handover_to",
				recipient: toAgent._id,
				message: `Ticket #${ticket._id} has been handed over to you from ${fromAgent.name}`,
			},
		];

		await Notification.insertMany(notifications);
	}

	async getAgentMetrics(agentId, startDate, endDate) {
		const metrics = await Ticket.aggregate([
			{
				$match: {
					assignedTo: mongoose.Types.ObjectId(agentId),
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
					slaCompliance: {
						$avg: {
							$cond: [
								{ $and: ["$sla.responseTime.met", "$sla.resolutionTime.met"] },
								1,
								0,
							],
						},
					},
				},
			},
		]);

		return (
			metrics[0] || {
				totalTickets: 0,
				resolvedTickets: 0,
				averageResolutionTime: 0,
				slaCompliance: 0,
			}
		);
	}

	// Other methods can be similarly modified to remove transaction usage
}

module.exports = new AgentService();
