const Ticket = require("../models/Ticket");
const Agent = require("../models/Agent");
const mongoose = require("mongoose");

class TicketService {
	async createTicket(ticketData) {
		const ticket = new Ticket(ticketData);
		await ticket.save();

		// If no specific agent is assigned, try automatic assignment
		if (!ticket.assignedTo) {
			await this.attemptAutoAssignment(ticket);
		}

		return ticket;
	}

	async attemptAutoAssignment(ticket) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const availableAgent = await this.findSuitableAgent(ticket);
			if (!availableAgent) {
				return null;
			}

			ticket.assignedTo = availableAgent._id;
			ticket.status = "assigned";
			await ticket.save({ session });

			availableAgent.currentLoad += ticket.estimatedHours;
			availableAgent.currentTicket = ticket._id;
			await availableAgent.save({ session });

			await session.commitTransaction();
			return availableAgent;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async findSuitableAgent(ticket) {
		const currentTime = new Date();
		return await Agent.findOne({
			status: "online",
			currentLoad: { $lt: 8 },
			"shift.end": {
				$gt: new Date(
					currentTime.getTime() + ticket.estimatedHours * 60 * 60 * 1000
				),
			},
			currentTicket: null,
		}).sort("currentLoad");
	}

	async processQueue() {
		const queuedTickets = await Ticket.find({
			status: "queued",
			assignedTo: null,
		}).sort("createdAt");

		const results = {
			processed: 0,
			assigned: 0,
			failed: 0,
		};

		for (const ticket of queuedTickets) {
			results.processed++;
			try {
				const agent = await this.attemptAutoAssignment(ticket);
				if (agent) {
					results.assigned++;
				}
			} catch (error) {
				results.failed++;
				console.error(`Failed to assign ticket ${ticket._id}:`, error);
			}
		}

		return results;
	}

	async getTicketsByStatus(status) {
		return await Ticket.find({ status })
			.populate("assignedTo", "name email")
			.sort("-createdAt");
	}
}

module.exports = new TicketService();
