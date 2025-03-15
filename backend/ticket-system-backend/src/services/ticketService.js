const Ticket = require("../models/Ticket");
const Agent = require("../models/Agent");
const User = require("../models/User");
const Notification = require("../models/Notification");
const { EventEmitter } = require("events");
const logger = require("../utils/logger");

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
		try {
			// Create ticket without transactions
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

			await ticket.save();

			if (ticketData.assignedTo) {
				await this.assignTicket(ticket._id, ticketData.assignedTo);
			} else {
				await this.attemptAutoAssignment(ticket);
			}

			ticketEvents.emit("ticket:created", ticket);
			return ticket;
		} catch (error) {
			console.error("Error creating ticket:", error);
			throw error;
		}
	}

	async attemptAutoAssignment(ticket) {
		const suitableAgent = await this.findOptimalAgent(ticket);
		if (suitableAgent) {
			await this.assignTicket(ticket._id, suitableAgent._id);
			return suitableAgent;
		}
		return null;
	}

	async findOptimalAgent(ticket) {
		const now = new Date();
		const requiredSkills = ticket.requiredSkills || [];

		// Find agents with matching skills, available capacity, and online status
		const agents = await Agent.find({
			status: "online",
			currentLoad: { $lt: 8 },
			department: ticket.department,
		}).exec();

		// If no available agents, return null
		if (!agents.length) return null;

		// Score and sort agents based on multiple factors
		const scoredAgents = agents
			.map((agent) => {
				// Basic availability check
				if (agent.currentTicket || !this.isAgentAvailable(agent, ticket, now)) {
					return { agent, score: -1 }; // Mark as unavailable
				}

				// Calculate skill match score
				const skillMatch = this.calculateSkillMatch(agent, requiredSkills);

				// Calculate load score (prefer agents with less current load)
				const loadScore = 8 - agent.currentLoad;

				// Calculate experience score based on performance metrics
				const experienceScore = agent.performance?.slaComplianceRate || 0;

				// Calculate total score with weighted factors
				const totalScore =
					skillMatch * 2 + // Skills are important
					loadScore + // Load balancing
					experienceScore * 1.5; // Reward high performers

				return { agent, score: totalScore };
			})
			.filter((item) => item.score >= 0) // Remove unavailable agents
			.sort((a, b) => b.score - a.score); // Sort by descending score

		// Return the highest-scoring agent, or null if none available
		return scoredAgents.length > 0 ? scoredAgents[0].agent : null;
	}

	isAgentAvailable(agent, ticket, now) {
		// Check if agent has shift and is within shift hours
		if (!agent.shift || !agent.shift.start || !agent.shift.end) {
			return false;
		}

		if (now < agent.shift.start || now > agent.shift.end) {
			return false;
		}

		// Check if agent is on break
		if (agent.shift.breaks && agent.shift.breaks.length > 0) {
			const isOnBreak = agent.shift.breaks.some(
				(breakPeriod) => now >= breakPeriod.start && now <= breakPeriod.end
			);
			if (isOnBreak) return false;
		}

		// Check if agent has capacity for the ticket
		const estimatedEndTime = new Date(
			now.getTime() + ticket.estimatedHours * 60 * 60 * 1000
		);
		if (estimatedEndTime > agent.shift.end) {
			return false;
		}

		return true;
	}

	calculateSkillMatch(agent, requiredSkills) {
		if (!requiredSkills.length) return 1; // If no skills required, full match

		const agentSkills = agent.skills || [];
		if (!agentSkills.length) return 0; // Agent has no skills

		// If string array format, convert to array of objects with skill names
		const agentSkillNames = agentSkills.map((skill) =>
			typeof skill === "string" ? skill : skill.name
		);

		// Count how many required skills the agent has
		let matchCount = 0;
		for (const skill of requiredSkills) {
			const skillName = typeof skill === "string" ? skill : skill.name;
			if (agentSkillNames.includes(skillName)) {
				matchCount++;
			}
		}

		return matchCount / requiredSkills.length;
	}

	async assignTicket(ticketId, agentId) {
		try {
			const [ticket, agent] = await Promise.all([
				Ticket.findById(ticketId),
				Agent.findById(agentId),
			]);

			if (!ticket || !agent) {
				throw new Error("Ticket or agent not found");
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
			agent.activeTickets = agent.activeTickets || [];
			agent.activeTickets.push(ticket._id);

			await Promise.all([ticket.save(), agent.save()]);
			logger.info(`Ticket ${ticketId} assigned to agent ${agentId}`);

			ticketEvents.emit("ticket:assigned", { ticket, agent });

			return { ticket, agent };
		} catch (error) {
			logger.error(
				`Error assigning ticket ${ticketId} to agent ${agentId}: ${error.message}`
			);
			throw error;
		}
	}

	async processQueue() {
		try {
			logger.info("Starting queue processing");

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
					// Check if ticket needs escalation due to SLA breach
					if (this.doesTicketNeedEscalation(ticket)) {
						await this.escalateTicket(ticket._id);
						results.escalated++;
						continue;
					}

					// Try to assign to an agent
					const agent = await this.attemptAutoAssignment(ticket);
					if (agent) {
						results.assigned++;
					}
				} catch (error) {
					results.failed++;
					logger.error(
						`Failed to process ticket ${ticket._id}: ${error.message}`
					);
				}
			}

			logger.info(`Queue processing completed: ${JSON.stringify(results)}`);
			return results;
		} catch (error) {
			logger.error(`Error processing queue: ${error.message}`);
			throw error;
		}
	}

	async resolveEscalation(ticketId, userId) {
		try {
			const ticket = await Ticket.findById(ticketId);
			if (!ticket) {
				throw new Error("Ticket not found");
			}

			// Store previous values
			const prevEscalationLevel = ticket.escalationLevel;
			const prevStatus = ticket.status;

			// Reset escalation
			ticket.escalationLevel = 0;
			if (ticket.status === "escalated") {
				ticket.status = "in-progress";
			}

			// Use "status_updated" since it's an existing valid action
			ticket.history.push({
				action: "status_updated",
				performedBy: userId,
				details: {
					oldStatus: prevStatus,
					newStatus: ticket.status,
					escalationResolved: true,
					previousEscalationLevel: prevEscalationLevel,
				},
			});

			await ticket.save();
			return ticket;
		} catch (error) {
			console.error(
				`Error resolving escalation for ticket ${ticketId}: ${error.message}`
			);
			throw error;
		}
	}

	doesTicketNeedEscalation(ticket) {
		// Check if ticket has SLA configuration
		if (!ticket.sla) return false;

		const now = new Date();

		// Check response time SLA breach
		if (
			ticket.sla.responseTime &&
			!ticket.sla.responseTime.met &&
			ticket.sla.responseTime.deadline &&
			now > new Date(ticket.sla.responseTime.deadline)
		) {
			return true;
		}

		// Check resolution time SLA breach
		if (
			ticket.sla.resolutionTime &&
			!ticket.sla.resolutionTime.met &&
			ticket.sla.resolutionTime.deadline &&
			now > new Date(ticket.sla.resolutionTime.deadline)
		) {
			return true;
		}

		return false;
	}

	async determineEscalationLevel(ticket) {
		// Basic escalation - increment current level
		let newLevel = (ticket.escalationLevel || 0) + 1;

		// Max escalation level is 3
		if (newLevel > 3) newLevel = 3;

		// Advanced: Adjust based on ticket priority
		if (ticket.priority === 1) {
			// High priority
			// High priority tickets escalate faster
			newLevel = Math.min(newLevel + 1, 3);
		}

		return newLevel;
	}

	async escalateTicket(ticketId) {
		try {
			const ticket = await Ticket.findById(ticketId);
			if (!ticket) {
				throw new Error("Ticket not found");
			}

			// Determine appropriate escalation level
			const newLevel = await this.determineEscalationLevel(ticket);
			ticket.escalationLevel = newLevel;
			ticket.status = "escalated";

			// Add escalation reason to history
			ticket.history.push({
				action: "escalated",
				details: {
					reason: "SLA breach",
					previousLevel: ticket.escalationLevel - 1,
					newLevel: newLevel,
				},
			});

			// High-level escalations should go to senior staff
			if (newLevel >= 2) {
				const seniorAgent = await this.findSeniorAgent(ticket);
				if (seniorAgent) {
					await this.assignTicket(ticket._id, seniorAgent._id);
				}
			}

			await ticket.save();
			await this.notifyEscalation(ticket);

			return ticket;
		} catch (error) {
			logger.error(`Error escalating ticket ${ticketId}: ${error.message}`);
			throw error;
		}
	}

	async notifyEscalation(ticket) {
		try {
			// Get admin fallback if there's no department
			const admins = await User.find({ role: "admin" }).select("_id");
			const recipients =
				(await this.getEscalationRecipients(ticket.department)) ||
				admins.map((admin) => admin._id);

			if (recipients.length === 0) {
				logger.warn(
					`No recipients for ticket ${ticket._id} escalation, notification skipped`
				);
				return;
			}

			// Create individual notifications
			const notifications = recipients.map((recipient) => ({
				type: "escalation",
				ticket: ticket._id,
				recipient: recipient,
				message: `Ticket #${ticket._id} has been escalated to level ${ticket.escalationLevel}`,
				metadata: {
					priority: ticket.priority,
					escalationLevel: ticket.escalationLevel,
					department: ticket.department,
					ticketTitle: ticket.title,
				},
			}));

			await Notification.insertMany(notifications);
			logger.info(
				`Created ${notifications.length} escalation notifications for ticket ${ticket._id}`
			);
		} catch (error) {
			logger.error(`Error creating escalation notification: ${error.message}`);
		}
	}

	async findSeniorAgent(ticket) {
		return await Agent.findOne({
			department: ticket.department,
			"skills.level": { $gte: 4 },
			status: "online",
			currentLoad: { $lt: 5 },
		});
	}

	async getEscalationRecipients(department) {
		// First make sure department is valid
		if (!department) {
			logger.warn("No department specified for escalation notification");

			// Fallback to all admins if no department
			const admins = await User.find({
				role: "admin",
			}).select("_id");

			return admins.map((admin) => admin._id);
		}

		const supervisors = await User.find({
			role: { $in: ["supervisor", "manager", "admin"] },
			department,
		}).select("_id");

		if (supervisors.length === 0) {
			logger.warn(`No supervisors found for department: ${department}`);
			// Fallback to admins
			const admins = await User.find({
				role: "admin",
			}).select("_id");
			return admins.map((admin) => admin._id);
		}

		return supervisors.map((s) => s._id);
	}

	async handleSLABreach(ticket) {
		logger.warn(`SLA breach detected for ticket ${ticket._id}`);
		try {
			await this.escalateTicket(ticket._id);
		} catch (error) {
			logger.error(`Error handling SLA breach: ${error.message}`);
		}
	}

	async handleTicketCreated(ticket) {
		logger.info(`Handling ticket created event for ${ticket._id}`);
		this.scheduleSLACheck(ticket);
	}

	async handleTicketAssigned(data) {
		const { ticket, agent } = data;
		logger.info(
			`Handling ticket assigned event for ${ticket._id} to ${agent._id}`
		);

		// Mark first response time if not already set
		if (!ticket.firstResponseTime) {
			ticket.firstResponseTime = new Date();
			if (ticket.sla && ticket.sla.responseTime) {
				ticket.sla.responseTime.met = true;
			}
			await ticket.save();
		}
	}

	async handleTicketUpdated(ticket) {
		logger.info(`Handling ticket updated event for ${ticket._id}`);
		await this.checkAndUpdateSLA(ticket);
	}

	scheduleSLACheck(ticket) {
		if (!ticket.sla) return;

		// Schedule response time check if applicable
		if (
			ticket.sla.responseTime &&
			!ticket.sla.responseTime.met &&
			ticket.sla.responseTime.deadline
		) {
			const responseDeadline = new Date(ticket.sla.responseTime.deadline);
			const timeUntilResponseCheck = responseDeadline - Date.now();

			if (timeUntilResponseCheck > 0) {
				setTimeout(async () => {
					await this.checkResponseSLA(ticket._id);
				}, timeUntilResponseCheck);
				logger.info(
					`Scheduled response SLA check for ticket ${ticket._id} in ${timeUntilResponseCheck}ms`
				);
			}
		}

		// Schedule resolution time check if applicable
		if (
			ticket.sla.resolutionTime &&
			!ticket.sla.resolutionTime.met &&
			ticket.sla.resolutionTime.deadline
		) {
			const resolutionDeadline = new Date(ticket.sla.resolutionTime.deadline);
			const timeUntilResolutionCheck = resolutionDeadline - Date.now();

			if (timeUntilResolutionCheck > 0) {
				setTimeout(async () => {
					await this.checkResolutionSLA(ticket._id);
				}, timeUntilResolutionCheck);
				logger.info(
					`Scheduled resolution SLA check for ticket ${ticket._id} in ${timeUntilResolutionCheck}ms`
				);
			}
		}
	}

	async checkResponseSLA(ticketId) {
		try {
			const ticket = await Ticket.findById(ticketId);
			if (!ticket || !ticket.sla || ticket.sla.responseTime.met) return;

			if (new Date() > ticket.sla.responseTime.deadline) {
				console.log(`SLA breach detected for ticket ${ticketId}`);
				ticketEvents.emit("sla:breach", ticket);
			}
		} catch (error) {
			logger.error(
				`Error checking response SLA for ticket ${ticketId}: ${error.message}`
			);
		}
	}

	async checkResolutionSLA(ticketId) {
		try {
			const ticket = await Ticket.findById(ticketId);
			if (
				!ticket ||
				!ticket.sla ||
				ticket.sla.resolutionTime.met ||
				ticket.status === "resolved" ||
				ticket.status === "closed"
			) {
				return;
			}

			if (new Date() > new Date(ticket.sla.resolutionTime.deadline)) {
				logger.warn(`Resolution SLA breached for ticket ${ticketId}`);
				ticketEvents.emit("sla:breach", ticket);
			}
		} catch (error) {
			logger.error(
				`Error checking resolution SLA for ticket ${ticketId}: ${error.message}`
			);
		}
	}

	async updateTicketStatus(ticketId, newStatus, userId) {
		try {
			const ticket = await Ticket.findById(ticketId).populate(
				"assignedTo",
				"name email status"
			);
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

			// Special handling for resolved tickets
			if (newStatus === "resolved") {
				ticket.resolvedAt = new Date();
				ticket.resolutionTime = Math.round(
					(ticket.resolvedAt - ticket.createdAt) / (1000 * 60)
				); // in minutes

				if (ticket.sla && ticket.sla.resolutionTime) {
					ticket.sla.resolutionTime.met = true;
				}

				await this.handleTicketResolution(ticket);
			}

			await ticket.save();
			logger.info(
				`Ticket ${ticketId} status updated from ${oldStatus} to ${newStatus}`
			);

			ticketEvents.emit("ticket:updated", ticket);
			return ticket;
		} catch (error) {
			logger.error(
				`Error updating ticket ${ticketId} status: ${error.message}`
			);
			throw error;
		}
	}

	async handleTicketResolution(ticket) {
		if (!ticket.assignedTo) return;

		try {
			const agent = await Agent.findById(ticket.assignedTo);
			if (!agent) return;

			// Update agent performance metrics
			agent.performance = agent.performance || {};
			agent.performance.ticketsResolved =
				(agent.performance.ticketsResolved || 0) + 1;

			// Update agent workload
			agent.currentLoad = Math.max(
				0,
				agent.currentLoad - ticket.estimatedHours
			);

			// Remove ticket from agent's active tickets
			agent.activeTickets = (agent.activeTickets || []).filter(
				(t) => t.toString() !== ticket._id.toString()
			);

			// Clear current ticket if this was it
			if (agent.currentTicket && ticket._id.equals(agent.currentTicket)) {
				agent.currentTicket = null;
			}

			await agent.save();
			logger.info(`Agent ${agent._id} metrics updated after ticket resolution`);
		} catch (error) {
			logger.error(
				`Error handling ticket resolution for agent: ${error.message}`
			);
			// Don't throw - agent update failure shouldn't block ticket resolution
		}
	}

	async getTicketMetrics(startDate, endDate) {
		try {
			const metrics = await Ticket.aggregate([
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
											{
												$and: [
													{ $ne: ["$sla.responseTime.met", true] },
													{ $lt: ["$NOW", "$sla.responseTime.deadline"] },
												],
											},
											{
												$and: [
													{ $ne: ["$sla.resolutionTime.met", true] },
													{ $lt: ["$NOW", "$sla.resolutionTime.deadline"] },
												],
											},
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

			return (
				metrics[0] || {
					totalTickets: 0,
					resolvedTickets: 0,
					averageResolutionTime: 0,
					slaBreaches: 0,
				}
			);
		} catch (error) {
			logger.error(`Error getting ticket metrics: ${error.message}`);
			throw error;
		}
	}
}

module.exports = new TicketService();
