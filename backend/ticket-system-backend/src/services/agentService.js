const Agent = require("../models/Agent");
const Ticket = require("../models/Ticket");

class AgentService {
	async updateAgentStatus(agentId, status) {
		const agent = await Agent.findById(agentId);
		if (!agent) {
			throw new Error("Agent not found");
		}

		agent.status = status;

		// If agent goes offline, reassign their current ticket
		if (status === "offline" && agent.currentTicket) {
			await this.handleAgentOffline(agent);
		}

		return await agent.save();
	}

	async handleAgentOffline(agent) {
		const ticket = await Ticket.findById(agent.currentTicket);
		if (ticket) {
			ticket.status = "queued";
			ticket.assignedTo = null;
			await ticket.save();

			agent.currentTicket = null;
			agent.currentLoad = Math.max(
				0,
				agent.currentLoad - ticket.estimatedHours
			);
		}
	}

	async claimTicket(agentId, ticketId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const [agent, ticket] = await Promise.all([
				Agent.findById(agentId),
				Ticket.findById(ticketId),
			]);

			if (!agent || !ticket) {
				throw new Error("Agent or ticket not found");
			}

			if (agent.status !== "online" || agent.currentTicket) {
				throw new Error("Agent not available to claim ticket");
			}

			const shiftEndTime = new Date(agent.shift.end);
			const estimatedCompletionTime = new Date(
				Date.now() + ticket.estimatedHours * 60 * 60 * 1000
			);

			if (estimatedCompletionTime > shiftEndTime) {
				throw new Error("Cannot complete ticket within shift hours");
			}

			ticket.assignedTo = agent._id;
			ticket.status = "assigned";
			await ticket.save({ session });

			agent.currentTicket = ticket._id;
			agent.currentLoad += ticket.estimatedHours;
			await agent.save({ session });

			await session.commitTransaction();
			return { agent, ticket };
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async getAvailableAgents() {
		return await Agent.find({
			status: "online",
			currentTicket: null,
		}).select("-__v");
	}

	async updateShiftSchedule(agentId, shiftData) {
		const agent = await Agent.findById(agentId);
		if (!agent) {
			throw new Error("Agent not found");
		}

		agent.shift = shiftData;
		return await agent.save();
	}
}

module.exports = new AgentService();
