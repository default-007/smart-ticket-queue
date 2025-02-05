const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");
const Notification = require("../models/Notification");
const mongoose = require("mongoose");
const { EventEmitter } = require("events");

class AgentEvents extends EventEmitter {}
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
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			const oldStatus = agent.status;
			agent.status = status;

			// If agent goes offline, handle their current tickets
			if (status === "offline" && agent.activeTickets.length > 0) {
				await this.handleAgentOffline(agent, session);
			}

			await agent.save({ session });
			await session.commitTransaction();

			agentEvents.emit("agent:status_changed", { agent, oldStatus });
			return agent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async handleAgentOffline(agent, session) {
		// Reassign or queue current tickets
		const tickets = await Ticket.find({
			_id: { $in: agent.activeTickets },
		}).session(session);

		for (const ticket of tickets) {
			ticket.status = "queued";
			ticket.assignedTo = null;
			ticket.history.push({
				action: "reassigned",
				details: { reason: "agent_offline", previousAgent: agent._id },
			});
			await ticket.save({ session });
		}

		agent.currentTicket = null;
		agent.activeTickets = [];
		agent.currentLoad = 0;
	}

	async startAgentShift(agentId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			agent.status = "online";
			agent.shift.start = new Date();
			agent.shift.end = new Date(Date.now() + 8 * 60 * 60 * 1000); // 8-hour shift

			await agent.save({ session });
			await session.commitTransaction();

			agentEvents.emit("agent:shift_started", agent);

			// Schedule shift end notification
			this.scheduleShiftEndNotification(agent);

			return agent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
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
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const tickets = await Ticket.find({
				_id: { $in: agent.activeTickets },
			}).session(session);

			// Find available agents for handover
			const availableAgents = await this.findHandoverAgents(agent.department);

			for (const ticket of tickets) {
				const targetAgent = this.selectHandoverAgent(availableAgents, ticket);
				if (targetAgent) {
					await this.handoverTicket(ticket, agent, targetAgent, session);
				}
			}

			await session.commitTransaction();
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async handoverTicket(ticket, fromAgent, toAgent, session) {
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

		await Promise.all([
			ticket.save({ session }),
			toAgent.save({ session }),
			fromAgent.save({ session }),
		]);

		// Notify both agents
		await this.createHandoverNotifications(ticket, fromAgent, toAgent, session);
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

	async createHandoverNotifications(ticket, fromAgent, toAgent, session) {
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

		await Notification.insertMany(notifications, { session });
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

	async updateAgentSkills(agentId, skills) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			// Validate skills format
			this.validateSkills(skills);

			// Check if skill updates affect current ticket assignments
			if (agent.activeTickets.length > 0) {
				await this.validateSkillsAgainstActiveTickets(agent, skills, session);
			}

			// Update agent skills
			agent.skills = skills;
			agent.markModified("skills");

			// Add to history
			agent.history.push({
				action: "skills_updated",
				timestamp: new Date(),
				details: {
					previousSkills: agent.skills,
					newSkills: skills,
				},
			});

			await agent.save({ session });

			await session.commitTransaction();
			agentEvents.emit("agent:skills_updated", { agent, skills });

			return agent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async validateSkillsAgainstActiveTickets(agent, newSkills, session) {
		const activeTickets = await Ticket.find({
			_id: { $in: agent.activeTickets },
		}).session(session);

		const incompatibleTickets = activeTickets.filter((ticket) => {
			return !this.hasRequiredSkillsForTicket(newSkills, ticket.requiredSkills);
		});

		if (incompatibleTickets.length > 0) {
			await this.handleIncompatibleTickets(agent, incompatibleTickets, session);
		}
	}

	hasRequiredSkillsForTicket(agentSkills, requiredSkills) {
		return requiredSkills.every((required) => {
			const matchingSkill = agentSkills.find(
				(skill) => skill.name === required.name
			);
			return matchingSkill && matchingSkill.level >= required.level;
		});
	}

	async handleIncompatibleTickets(agent, incompatibleTickets, session) {
		for (const ticket of incompatibleTickets) {
			// Try to find another suitable agent
			const newAgent = await this.findSuitableReplacementAgent(
				ticket,
				agent._id
			);

			if (newAgent) {
				await this.handoverTicket(ticket, agent, newAgent, session);
			} else {
				// If no suitable agent found, return ticket to queue
				await this.returnTicketToQueue(ticket, agent, session);
			}
		}
	}

	async returnTicketToQueue(ticket, agent, session) {
		ticket.status = "queued";
		ticket.assignedTo = null;
		ticket.history.push({
			action: "requeued",
			timestamp: new Date(),
			details: {
				reason: "agent_skill_update",
				previousAgent: agent._id,
			},
		});

		// Update agent's workload
		agent.currentLoad = Math.max(0, agent.currentLoad - ticket.estimatedHours);
		agent.activeTickets = agent.activeTickets.filter(
			(t) => t.toString() !== ticket._id.toString()
		);

		await Promise.all([
			ticket.save({ session }),
			agent.save({ session }),
			this.createTicketReassignmentNotification(ticket, agent, session),
		]);
	}

	async createTicketReassignmentNotification(ticket, agent, session) {
		const notification = new Notification({
			type: "ticket_reassignment",
			recipient: agent._id,
			ticket: ticket._id,
			message: `Ticket #${ticket._id} has been returned to queue due to skill requirements`,
			metadata: {
				ticketTitle: ticket.title,
				reason: "skill_update",
			},
		});

		await notification.save({ session });
	}

	// Batch update capabilities for admin operations
	async batchUpdateAgentSkills(updates) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const results = {
				successful: [],
				failed: [],
			};

			for (const update of updates) {
				try {
					const updatedAgent = await this.updateAgentSkills(
						update.agentId,
						update.skills,
						session
					);
					results.successful.push({
						agentId: update.agentId,
						agent: updatedAgent,
					});
				} catch (error) {
					results.failed.push({
						agentId: update.agentId,
						error: error.message,
					});
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

	// Team management functions
	async assignAgentToTeam(agentId, teamId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			if (!agent.teams.includes(teamId)) {
				agent.teams.push(teamId);
				await agent.save({ session });
			}

			await session.commitTransaction();
			return agent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	// Performance tracking
	async updateAgentPerformance(agentId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			const thirtyDaysAgo = new Date();
			thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

			const metrics = await this.getAgentMetrics(
				agentId,
				thirtyDaysAgo,
				new Date()
			);

			agent.performance = {
				...agent.performance,
				...metrics,
				lastUpdated: new Date(),
			};

			await agent.save({ session });
			await session.commitTransaction();

			return agent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	// Utility methods for skill management
	validateSkills(skills) {
		if (!Array.isArray(skills)) {
			throw new Error("Skills must be an array");
		}

		skills.forEach((skill) => {
			if (!skill.name || typeof skill.name !== "string") {
				throw new Error("Each skill must have a valid name");
			}
			if (
				!skill.level ||
				typeof skill.level !== "number" ||
				skill.level < 1 ||
				skill.level > 5
			) {
				throw new Error("Each skill must have a level between 1 and 5");
			}
		});
	}

	// Event handlers
	async handleSkillsUpdated({ agent, skills }) {
		// Trigger any necessary system updates or notifications
		await this.updateAgentPerformance(agent._id);

		// Notify relevant team members or supervisors
		if (agent.teams.length > 0) {
			await this.notifyTeamOfSkillUpdate(agent, skills);
		}
	}

	async notifyTeamOfSkillUpdate(agent, skills) {
		const teamManagers = await Agent.find({
			teams: { $in: agent.teams },
			role: "manager",
		});

		const notifications = teamManagers.map((manager) => ({
			type: "skill_update",
			recipient: manager._id,
			message: `${agent.name}'s skills have been updated`,
			metadata: {
				agentId: agent._id,
				skills: skills,
			},
		}));

		if (notifications.length > 0) {
			await Notification.insertMany(notifications);
		}
	}
}

module.exports = new AgentService();
