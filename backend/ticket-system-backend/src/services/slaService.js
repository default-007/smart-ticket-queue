// services/slaService.js
const Ticket = require("../models/Ticket");
const SLAConfig = require("../models/SLAConfig");
const NotificationService = require("./notificationService");
const mongoose = require("mongoose");

class SLAService {
	constructor() {
		this.notificationService = NotificationService;
		this.startMonitoring();
	}

	startMonitoring() {
		// Check SLA compliance every minute
		setInterval(async () => {
			await this.checkAllTicketsSLA();
		}, 60000);
	}

	async checkAllTicketsSLA() {
		const activeTickets = await Ticket.find({
			status: { $nin: ["resolved", "closed"] },
		});

		for (const ticket of activeTickets) {
			await this.checkTicketSLA(ticket);
		}
	}

	async checkTicketSLA(ticket) {
		const now = new Date();
		let needsEscalation = false;

		// Check response time SLA
		if (
			!ticket.sla.responseTime.met &&
			now > ticket.sla.responseTime.deadline
		) {
			needsEscalation = true;
			await this.handleSLABreach(ticket, "response_time");
		}

		// Check resolution time SLA
		if (
			!ticket.sla.resolutionTime.met &&
			now > ticket.sla.resolutionTime.deadline
		) {
			needsEscalation = true;
			await this.handleSLABreach(ticket, "resolution_time");
		}

		if (needsEscalation) {
			await this.escalateTicket(ticket);
		}
	}

	async handleSLABreach(ticket, breachType) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			// Update ticket with breach information
			ticket.history.push({
				action: "sla_breach",
				details: { breachType },
			});

			await ticket.save({ session });

			// Create notification
			await this.notificationService.createSLABreachNotification(ticket);

			await session.commitTransaction();
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async escalateTicket(ticket) {
		if (ticket.status === "escalated") return;

		const ticketService = require("./ticketService");
		await ticketService.escalateTicket(ticket._id);
	}

	async getSLAConfig(priority, category) {
		const config = await SLAConfig.findOne({ priority, category });
		if (!config) {
			throw new Error("SLA configuration not found");
		}
		return config;
	}

	async calculateSLADeadlines(ticket) {
		const config = await this.getSLAConfig(ticket.priority, ticket.category);
		const now = new Date();

		return {
			responseTime: {
				deadline: new Date(now.getTime() + config.responseTime * 60000),
				met: false,
			},
			resolutionTime: {
				deadline: new Date(now.getTime() + config.resolutionTime * 60000),
				met: false,
			},
		};
	}

	async markResponseSLAMet(ticketId) {
		await Ticket.findByIdAndUpdate(ticketId, {
			"sla.responseTime.met": true,
		});
	}

	async markResolutionSLAMet(ticketId) {
		await Ticket.findByIdAndUpdate(ticketId, {
			"sla.resolutionTime.met": true,
		});
	}

	async getSLAMetrics(startDate, endDate, department) {
		const match = {
			createdAt: { $gte: startDate, $lte: endDate },
		};

		if (department) {
			match.department = department;
		}

		return await Ticket.aggregate([
			{ $match: match },
			{
				$group: {
					_id: null,
					totalTickets: { $sum: 1 },
					responseSLABreaches: {
						$sum: {
							$cond: [
								{
									$and: [
										{ $gt: ["$sla.responseTime.deadline", "$NOW"] },
										{ $eq: ["$sla.responseTime.met", false] },
									],
								},
								1,
								0,
							],
						},
					},
					resolutionSLABreaches: {
						$sum: {
							$cond: [
								{
									$and: [
										{ $gt: ["$sla.resolutionTime.deadline", "$NOW"] },
										{ $eq: ["$sla.resolutionTime.met", false] },
									],
								},
								1,
								0,
							],
						},
					},
					averageResponseTime: {
						$avg: {
							$subtract: ["$firstResponseTime", "$createdAt"],
						},
					},
					averageResolutionTime: {
						$avg: {
							$subtract: ["$resolvedAt", "$createdAt"],
						},
					},
					slaComplianceRate: {
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
			{
				$project: {
					_id: 0,
					totalTickets: 1,
					responseSLABreaches: 1,
					resolutionSLABreaches: 1,
					averageResponseTime: { $divide: ["$averageResponseTime", 60000] }, // Convert to minutes
					averageResolutionTime: { $divide: ["$averageResolutionTime", 60000] }, // Convert to minutes
					slaComplianceRate: { $multiply: ["$slaComplianceRate", 100] }, // Convert to percentage
				},
			},
		]);
	}
}

module.exports = new SLAService();
