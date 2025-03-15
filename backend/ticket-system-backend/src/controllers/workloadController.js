const asyncHandler = require("../utils/asyncHandler");
const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");
const mongoose = require("mongoose");

exports.getWorkloadMetrics = asyncHandler(async (req, res) => {
	try {
		const metrics = await Agent.aggregate([
			{ $match: { status: "online" } },
			{
				$group: {
					_id: null,
					totalAgents: { $sum: 1 },
					activeAgents: {
						$sum: { $cond: [{ $eq: ["$status", "online"] }, 1, 0] },
					},
					averageLoad: { $avg: "$currentLoad" },
					maxLoad: { $max: "$currentLoad" },
					overloadedAgents: {
						$sum: { $cond: [{ $gt: ["$currentLoad", 6] }, 1, 0] },
					},
					availableAgents: {
						$sum: { $cond: [{ $lt: ["$currentLoad", 5] }, 1, 0] },
					},
					// Count agents by workload category directly
					lowLoadCount: {
						$sum: { $cond: [{ $lt: ["$currentLoad", 3] }, 1, 0] },
					},
					moderateLoadCount: {
						$sum: {
							$cond: [
								{
									$and: [
										{ $gte: ["$currentLoad", 3] },
										{ $lt: ["$currentLoad", 6] },
									],
								},
								1,
								0,
							],
						},
					},
					highLoadCount: {
						$sum: {
							$cond: [
								{
									$and: [
										{ $gte: ["$currentLoad", 6] },
										{ $lt: ["$currentLoad", 8] },
									],
								},
								1,
								0,
							],
						},
					},
					overloadedCount: {
						$sum: { $cond: [{ $gte: ["$currentLoad", 8] }, 1, 0] },
					},
				},
			},
			{
				$project: {
					_id: 0,
					totalAgents: 1,
					activeAgents: 1,
					averageLoad: { $round: ["$averageLoad", 2] },
					maxLoad: 1,
					overloadedAgents: 1,
					availableAgents: 1,
					workloadDistribution: {
						low: "$lowLoadCount",
						moderate: "$moderateLoadCount",
						high: "$highLoadCount",
						overloaded: "$overloadedCount",
					},
				},
			},
		]);

		res.json({
			success: true,
			data: metrics[0] || {
				totalAgents: 0,
				activeAgents: 0,
				averageLoad: 0,
				maxLoad: 0,
				overloadedAgents: 0,
				availableAgents: 0,
				workloadDistribution: { low: 0, moderate: 0, high: 0, overloaded: 0 },
			},
		});
	} catch (error) {
		console.error("Error fetching workload metrics:", error);
		res.status(500).json({ success: false, message: error.message });
	}
});

exports.getAgentWorkloads = asyncHandler(async (req, res) => {
	try {
		// Get all online agents
		const agents = await Agent.find({
			status: { $in: ["online", "busy"] },
		});

		// Process each agent manually without using $nin in aggregation
		const agentWorkloads = [];

		for (const agent of agents) {
			// Get tickets assigned to this agent (avoiding $nin by using $ne multiple times)
			const tickets = await Ticket.find({
				assignedTo: agent._id,
				status: { $ne: "resolved" },
			}).find({
				status: { $ne: "closed" },
			});

			// Format response
			agentWorkloads.push({
				agentId: agent._id.toString(),
				agentName: agent.name,
				currentLoad: agent.currentLoad || 0,
				maxLoad: agent.maxTickets || 8,
				activeTickets: tickets.length,
				queuedTickets: 0,
				nextAvailableSlot: agent.shift?.end || new Date(),
				upcomingTasks: tickets.map((ticket) => ({
					taskId: ticket._id.toString(),
					title: ticket.title,
					startTime: new Date(),
					estimatedHours: ticket.estimatedHours || 1,
					priority: ticket.priority ? ticket.priority.toString() : "medium",
				})),
			});
		}

		res.json({
			success: true,
			data: agentWorkloads,
		});
	} catch (error) {
		console.error("Error fetching agent workloads:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.getTeamCapacities = asyncHandler(async (req, res) => {
	try {
		const teamCapacities = await Agent.aggregate([
			{
				$group: {
					_id: "$department",
					teamName: { $first: "$department" },
					totalAgents: { $sum: 1 },
					activeAgents: {
						$sum: { $cond: [{ $eq: ["$status", "online"] }, 1, 0] },
					},
					currentCapacity: { $sum: "$currentLoad" },
					maxCapacity: { $sum: "$maxTickets" },
					allAgents: { $push: "$$ROOT" }, // Keep all agents for skill processing
				},
			},
			{
				$project: {
					teamId: "$_id",
					teamName: 1,
					totalAgents: 1,
					activeAgents: 1,
					currentCapacity: { $round: ["$currentCapacity", 2] },
					maxCapacity: 1,
					// Extract unique skills
					skills: {
						$reduce: {
							input: "$allAgents",
							initialValue: [],
							in: { $setUnion: ["$$value", "$$this.skills"] },
						},
					},
					allAgents: 1, // Keep for counting
				},
			},
			{
				$project: {
					teamId: 1,
					teamName: 1,
					totalAgents: 1,
					activeAgents: 1,
					currentCapacity: 1,
					maxCapacity: 1,
					skills: 1,
					skillDistribution: {
						$arrayToObject: {
							$map: {
								input: "$skills",
								as: "skill",
								in: {
									k: "$$skill", // Key field required by $arrayToObject
									v: {
										// Value field required by $arrayToObject
										$size: {
											$filter: {
												input: "$allAgents",
												as: "agent",
												cond: { $in: ["$$skill", "$$agent.skills"] },
											},
										},
									},
								},
							},
						},
					},
				},
			},
		]);

		res.json({
			success: true,
			data: teamCapacities,
		});
	} catch (error) {
		console.error("Error fetching team capacities:", error);
		res.status(500).json({ success: false, message: error.message });
	}
});

exports.rebalanceWorkload = asyncHandler(async (req, res) => {
	try {
		// Find overloaded agents
		const overloadedAgents = await Agent.find({
			status: "online",
			currentLoad: { $gt: 6 },
		});

		// Find available agents to redistribute tickets
		const availableAgents = await Agent.find({
			status: "online",
			currentLoad: { $lt: 5 },
		});

		// Redistribute tickets
		for (const overloadedAgent of overloadedAgents) {
			// Find tickets assigned to overloaded agent
			const tickets = await Ticket.find({
				assignedTo: overloadedAgent._id,
				status: { $nin: ["resolved", "closed"] },
			}).sort({ priority: 1 });

			// Redistribute tickets to available agents
			for (const ticket of tickets) {
				const targetAgent = availableAgents.find(
					(agent) => agent.canHandleTicket && agent.canHandleTicket(ticket)
				);

				if (targetAgent) {
					// Reassign ticket
					ticket.assignedTo = targetAgent._id;
					ticket.history.push({
						action: "transferred",
						details: {
							fromAgent: overloadedAgent._id,
							toAgent: targetAgent._id,
							reason: "workload_rebalancing",
						},
					});

					// Update agent workloads
					overloadedAgent.currentLoad -= ticket.estimatedHours;
					overloadedAgent.activeTickets = overloadedAgent.activeTickets.filter(
						(t) => t.toString() !== ticket._id.toString()
					);

					targetAgent.currentLoad += ticket.estimatedHours;
					targetAgent.activeTickets.push(ticket._id);

					await Promise.all([
						ticket.save(),
						overloadedAgent.save(),
						targetAgent.save(),
					]);
				}
			}
		}

		res.json({
			success: true,
			message: "Workload rebalanced successfully",
		});
	} catch (error) {
		console.error("Error rebalancing workload:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.getWorkloadPredictions = asyncHandler(async (req, res) => {
	try {
		// Basic workload prediction based on current trends
		const predictions = {
			nextWeekLoad: {},
			ticketTrends: {},
			agentCapacityNeeds: {},
		};

		// Aggregate ticket creation trends
		const ticketTrends = await Ticket.aggregate([
			{
				$group: {
					_id: {
						year: { $year: "$createdAt" },
						month: { $month: "$createdAt" },
						day: { $dayOfMonth: "$createdAt" },
					},
					ticketCount: { $sum: 1 },
				},
			},
			{ $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1 } },
			{ $limit: 30 }, // Last 30 days
		]);

		// Predict next week's load
		const totalTickets = ticketTrends.reduce(
			(sum, day) => sum + day.ticketCount,
			0
		);
		const avgDailyTickets = totalTickets / ticketTrends.length;
		predictions.nextWeekLoad = {
			dailyAverage: avgDailyTickets,
			predictedTotal: avgDailyTickets * 7,
		};

		// Predict agent capacity needs
		const agentWorkloads = await Agent.aggregate([
			{
				$group: {
					_id: "$department",
					avgLoad: { $avg: "$currentLoad" },
					maxLoad: { $max: "$maxTickets" },
				},
			},
		]);

		predictions.agentCapacityNeeds = agentWorkloads.reduce((acc, dept) => {
			acc[dept._id] = {
				avgLoad: dept.avgLoad,
				maxLoad: dept.maxLoad,
				additionalAgentsNeeded: Math.max(
					0,
					Math.ceil(dept.avgLoad / dept.maxLoad - 1)
				),
			};
			return acc;
		}, {});

		res.json({
			success: true,
			data: predictions,
		});
	} catch (error) {
		console.error("Error fetching workload predictions:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.optimizeAssignments = asyncHandler(async (req, res) => {
	try {
		// Find unassigned tickets
		const unassignedTickets = await Ticket.find({
			status: "queued",
			assignedTo: null,
		}).sort({ priority: 1 });

		// Find available agents
		const availableAgents = await Agent.find({
			status: "online",
			currentLoad: { $lt: 6 },
		}).sort("currentLoad");

		// Optimize ticket assignments
		for (const ticket of unassignedTickets) {
			const optimalAgent = availableAgents.find(
				(agent) => agent.canHandleTicket && agent.canHandleTicket(ticket)
			);

			if (optimalAgent) {
				ticket.assignedTo = optimalAgent._id;
				ticket.status = "assigned";
				ticket.history.push({
					action: "assigned",
					details: {
						agent: optimalAgent._id,
						reason: "optimization",
					},
				});

				optimalAgent.currentLoad += ticket.estimatedHours; // Continuing from the previous cut-off line
				optimalAgent.activeTickets.push(ticket._id);

				await Promise.all([ticket.save(), optimalAgent.save()]);

				// Remove the agent from available agents if they're at capacity
				if (optimalAgent.currentLoad >= 6) {
					const index = availableAgents.findIndex((a) =>
						a._id.equals(optimalAgent._id)
					);
					if (index !== -1) availableAgents.splice(index, 1);
				}
			}

			// Break if no more available agents
			if (availableAgents.length === 0) break;
		}

		res.json({
			success: true,
			message: "Ticket assignments optimized successfully",
		});
	} catch (error) {
		console.error("Error optimizing ticket assignments:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});
