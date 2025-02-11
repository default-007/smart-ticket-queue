// src/services/workloadService.js
const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");
const mongoose = require("mongoose");

class WorkloadService {
	async calculateAgentWorkload(agentId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const activeTickets = await Ticket.find({
				assignedTo: agentId,
				status: { $nin: ["resolved", "closed"] },
			}).session(session);

			const workload = await Workload.findOne({ agent: agentId }).session(
				session
			);

			if (!workload) {
				const newWorkload = new Workload({
					agent: agentId,
					currentLoad: activeTickets.reduce(
						(total, ticket) => total + (ticket.estimatedHours || 0),
						0
					),
					activeTickets: activeTickets.map((ticket) => ticket._id),
				});

				await newWorkload.save({ session });
			} else {
				workload.currentLoad = activeTickets.reduce(
					(total, ticket) => total + (ticket.estimatedHours || 0),
					0
				);
				workload.activeTickets = activeTickets.map((ticket) => ticket._id);

				await workload.save({ session });
			}

			await session.commitTransaction();
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async redistributeWorkload() {
		const overloadedAgents = await Agent.find({
			status: "online",
			currentLoad: { $gt: 6 }, // 75% of max load
		});

		for (const agent of overloadedAgents) {
			await this.balanceAgentWorkload(agent);
		}
	}

	async balanceAgentWorkload(agent) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const tickets = await Ticket.find({
				_id: { $in: agent.activeTickets },
				status: { $nin: ["resolved", "closed"] },
			})
				.sort("priority")
				.session(session);

			for (const ticket of tickets) {
				const betterAgent = await this.findBetterAgent(ticket, agent);
				if (betterAgent) {
					await this.transferTicket(ticket, agent, betterAgent, session);
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

	async findBetterAgent(ticket, currentAgent) {
		return await Agent.findOne({
			_id: { $ne: currentAgent._id },
			status: "online",
			currentLoad: { $lt: currentAgent.currentLoad - 1 },
			department: ticket.department,
			"skills.name": { $all: ticket.requiredSkills || [] },
		});
	}

	async transferTicket(ticket, fromAgent, toAgent, session) {
		ticket.assignedTo = toAgent._id;
		ticket.history.push({
			action: "transferred",
			details: {
				fromAgent: fromAgent._id,
				toAgent: toAgent._id,
				reason: "workload_balancing",
			},
		});

		fromAgent.activeTickets = fromAgent.activeTickets.filter(
			(t) => t.toString() !== ticket._id.toString()
		);
		fromAgent.currentLoad = Math.max(
			0,
			fromAgent.currentLoad - ticket.estimatedHours
		);

		toAgent.activeTickets.push(ticket._id);
		toAgent.currentLoad += ticket.estimatedHours;

		await Promise.all([
			ticket.save({ session }),
			fromAgent.save({ session }),
			toAgent.save({ session }),
		]);
	}

	async getWorkloadSummary() {
		return await Agent.aggregate([
			{
				$match: { status: "online" },
			},
			{
				$group: {
					_id: "$department",
					totalAgents: { $sum: 1 },
					totalLoad: { $sum: "$currentLoad" },
					availableCapacity: {
						$sum: { $subtract: ["$maxTickets", "$currentLoad"] },
					},
					agentsAtCapacity: {
						$sum: {
							$cond: [{ $gte: ["$currentLoad", "$maxTickets"] }, 1, 0],
						},
					},
				},
			},
		]);
	}
}

module.exports = new WorkloadService();
