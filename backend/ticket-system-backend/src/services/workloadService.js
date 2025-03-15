// src/services/workloadService.js
const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");
const mongoose = require("mongoose");

class WorkloadService {
	async getWorkloadMetrics() {
		try {
			const metrics = await Agent.aggregate([
				{
					$match: {
						status: { $in: ["online", "busy"] },
					},
				},
				{
					$group: {
						_id: null,
						totalAgents: { $sum: 1 },
						activeAgents: {
							$sum: {
								$cond: [{ $eq: ["$status", "online"] }, 1, 0],
							},
						},
						currentLoad: { $sum: "$currentLoad" },
						overloadedAgents: {
							$sum: {
								$cond: [{ $gt: ["$currentLoad", 6] }, 1, 0],
							},
						},
					},
				},
				{
					$project: {
						_id: 0,
						totalAgents: 1,
						activeAgents: 1,
						averageLoad: {
							$cond: [
								{ $eq: ["$totalAgents", 0] },
								0,
								{ $divide: ["$currentLoad", "$totalAgents"] },
							],
						},
						maxLoad: { $literal: 8 },
						overloadedAgents: 1,
						availableAgents: {
							$subtract: ["$totalAgents", "$overloadedAgents"],
						},
						workloadDistribution: {
							$literal: {
								low: 0,
								moderate: 0,
								high: 0,
								overloaded: 0,
							},
						},
					},
				},
			]);

			// If no results, return default metrics
			return (
				metrics[0] || {
					totalAgents: 0,
					activeAgents: 0,
					averageLoad: 0,
					maxLoad: 8,
					overloadedAgents: 0,
					availableAgents: 0,
					workloadDistribution: {
						low: 0,
						moderate: 0,
						high: 0,
						overloaded: 0,
					},
				}
			);
		} catch (error) {
			console.error("Error fetching workload metrics:", error);
			throw this._handleError(error);
		}
	}

	async getAgentWorkloads() {
		try {
			// Get all agents with online or busy status
			const agents = await Agent.find({
				status: { $in: ["online", "busy"] },
			});

			// Process each agent to format the data
			const agentWorkloads = await Promise.all(
				agents.map(async (agent) => {
					// Get active tickets for this agent using a regular find query
					// instead of the aggregation with $nin
					const activeTickets = await Ticket.find({
						assignedTo: agent._id,
						status: { $ne: "resolved" }, // Individual $ne conditions
					}).find({
						status: { $ne: "closed" }, // Rather than $nin
					});

					return {
						agentId: agent._id.toString(),
						agentName: agent.name,
						currentLoad: agent.currentLoad || 0,
						maxLoad: agent.maxTickets || 8,
						activeTickets: activeTickets.length,
						queuedTickets: 0,
						nextAvailableSlot: agent.shift?.end || new Date(),
						upcomingTasks: activeTickets.map((ticket) => ({
							taskId: ticket._id.toString(),
							title: ticket.title,
							startTime: new Date(),
							estimatedHours: ticket.estimatedHours,
							priority: ticket.priority.toString(),
						})),
					};
				})
			);

			return agentWorkloads;
		} catch (error) {
			console.error("Error fetching agent workloads:", error);
			throw error;
		}
	}

	async getTeamCapacities() {
		try {
			// Get unique departments
			const departments = await Agent.distinct("department");

			// Process each department
			const teamCapacities = await Promise.all(
				departments.map(async (department) => {
					// Get all agents in this department
					const departmentAgents = await Agent.find({ department });

					// Calculate metrics
					const totalAgents = departmentAgents.length;
					const activeAgents = departmentAgents.filter(
						(a) => a.status === "online"
					).length;
					const currentCapacity = departmentAgents.reduce(
						(sum, agent) => sum + agent.currentLoad,
						0
					);
					const maxCapacity = totalAgents * 8;

					// Get unique skills across all agents
					const allSkills = new Set();
					departmentAgents.forEach((agent) => {
						if (agent.skills && Array.isArray(agent.skills)) {
							agent.skills.forEach((skill) =>
								allSkills.add(typeof skill === "string" ? skill : skill.name)
							);
						}
					});

					// Count agents with each skill
					const skillDistribution = {};
					Array.from(allSkills).forEach((skill) => {
						skillDistribution[skill] = departmentAgents.filter((agent) => {
							return (
								agent.skills &&
								agent.skills.some(
									(s) =>
										(typeof s === "string" && s === skill) ||
										(s.name && s.name === skill)
								)
							);
						}).length;
					});

					return {
						teamId: department,
						teamName: department,
						totalAgents,
						activeAgents,
						currentCapacity,
						maxCapacity,
						skills: Array.from(allSkills),
						skillDistribution,
					};
				})
			);

			return teamCapacities;
		} catch (error) {
			console.error("Error fetching team capacities:", error);
			throw this._handleError(error);
		}
	}

	async getWorkloadPredictions() {
		try {
			const now = new Date();
			const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

			// Simplified aggregation without complex operators
			const ticketCounts = await Ticket.aggregate([
				{
					$match: {
						createdAt: { $gte: oneWeekAgo, $lte: now },
					},
				},
				{
					$group: {
						_id: { $dayOfWeek: "$createdAt" },
						count: { $sum: 1 },
					},
				},
			]);

			// Calculate average daily tickets and total
			let totalTickets = 0;
			ticketCounts.forEach((day) => {
				totalTickets += day.count;
			});

			const dailyAverage =
				ticketCounts.length > 0
					? Math.round((totalTickets / ticketCounts.length) * 10) / 10
					: 0;

			return {
				nextWeekLoad: {
					dailyAverage: dailyAverage,
					predictedTotal: Math.round(dailyAverage * 7),
				},
				ticketTrends: {},
				agentCapacityNeeds: {
					Support: {
						avgLoad: dailyAverage,
						maxLoad: 8,
						additionalAgentsNeeded: Math.ceil(dailyAverage / 8),
					},
				},
			};
		} catch (error) {
			console.error("Error fetching workload predictions:", error);
			throw this._handleError(error);
		}
	}

	async rebalanceWorkload() {
		try {
			// Find overloaded agents
			const overloadedAgents = await Agent.find({
				status: "online",
				currentLoad: { $gt: 6 },
			});

			for (const agent of overloadedAgents) {
				// Get active tickets for this agent
				const tickets = await Ticket.find({
					assignedTo: agent._id,
					status: { $nin: ["resolved", "closed"] },
				}).sort("priority");

				for (const ticket of tickets) {
					// Find a better agent for this ticket
					const betterAgent = await this.findBetterAgent(ticket, agent);
					if (betterAgent) {
						await this.transferTicket(ticket, agent, betterAgent);
					}
				}
			}

			return { success: true, message: "Workload rebalanced successfully" };
		} catch (error) {
			console.error("Error rebalancing workload:", error);
			throw this._handleError(error);
		}
	}

	async findBetterAgent(ticket, currentAgent) {
		// Find an agent with less load who can handle this ticket
		return await Agent.findOne({
			_id: { $ne: currentAgent._id },
			status: "online",
			currentLoad: { $lt: currentAgent.currentLoad - 1 },
			department: ticket.department,
		});
	}

	async transferTicket(ticket, fromAgent, toAgent) {
		// Update ticket assignment
		ticket.assignedTo = toAgent._id;
		ticket.history.push({
			action: "transferred",
			details: {
				fromAgent: fromAgent._id,
				toAgent: toAgent._id,
				reason: "workload_balancing",
			},
		});

		// Update from agent workload
		fromAgent.activeTickets = fromAgent.activeTickets.filter(
			(t) => t.toString() !== ticket._id.toString()
		);
		fromAgent.currentLoad = Math.max(
			0,
			fromAgent.currentLoad - ticket.estimatedHours
		);

		// Update to agent workload
		toAgent.activeTickets.push(ticket._id);
		toAgent.currentLoad += ticket.estimatedHours;

		// Save all changes
		await Promise.all([ticket.save(), fromAgent.save(), toAgent.save()]);
	}

	async optimizeAssignments() {
		// Implement assignment optimization logic here
		return { success: true, message: "Assignments optimized" };
	}

	_handleError(error) {
		console.error("Workload Service Error:", error);
		return new Error("Failed to process workload operation");
	}
}

module.exports = new WorkloadService();
