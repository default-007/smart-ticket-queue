// services/slaService.js
const Ticket = require("../models/Ticket");
const SLAConfig = require("../models/SLAConfig");
const NotificationService = require("./notificationService");
const ticketService = require("../services/ticketService");

class SLAService {
	constructor() {
		this.notificationService = NotificationService;
		this.startMonitoring();
	}

	startMonitoring() {
		// Check SLA compliance every minute
		this.monitoringInterval = setInterval(async () => {
			try {
				await this.checkAllTicketsSLA();
			} catch (error) {
				console.error("Error in SLA monitoring:", error);
				// Continue running the monitoring despite errors
			}
		}, 60000);
	}

	// Add cleanup method
	stopMonitoring() {
		if (this.monitoringInterval) {
			clearInterval(this.monitoringInterval);
		}
	}

	async checkTicketSLA(ticket) {
		if (!ticket.sla) {
			console.log(`Ticket ${ticket._id} missing SLA fields, initializing...`);
			await this.initializeSLA(ticket);
			return;
		}
		const now = new Date();
		let needsEscalation = false;

		// First check if the ticket has SLA configuration
		/* if (!ticket.sla) {
			console.log(
				`Ticket ${ticket._id} does not have SLA configuration, skipping check`
			);
			return;
		} */

		// Check response time SLA
		if (
			ticket.sla.responseTime &&
			!ticket.sla.responseTime.met &&
			ticket.sla.responseTime.deadline &&
			now > ticket.sla.responseTime.deadline
		) {
			needsEscalation = true;
			await this.handleSLABreach(ticket, "response_time");
		}

		// Check resolution time SLA
		if (
			ticket.sla.resolutionTime &&
			!ticket.sla.resolutionTime.met &&
			ticket.sla.resolutionTime.deadline &&
			now > ticket.sla.resolutionTime.deadline
		) {
			needsEscalation = true;
			await this.handleSLABreach(ticket, "resolution_time");
		}
		if (needsEscalation) {
			await this.escalateTicket(ticket);
		}
	}

	// Also, make sure that when tickets are created, SLA is initialized properly
	async initializeSLA(ticket) {
		try {
			const config = await this.getSLAConfig(ticket.priority, ticket.category);
			const now = new Date();

			ticket.sla = {
				responseTime: {
					deadline: new Date(now.getTime() + config.responseTime * 60000),
					met: false,
				},
				resolutionTime: {
					deadline: new Date(now.getTime() + config.resolutionTime * 60000),
					met: false,
				},
			};

			await ticket.save();
			console.log(`SLA initialized for ticket ${ticket._id}`);
			return ticket;
		} catch (error) {
			console.error(`Error initializing SLA for ticket ${ticket._id}:`, error);
		}
	}

	async checkAllTicketsSLA() {
		try {
			const activeTickets = await Ticket.find({
				status: { $nin: ["resolved", "closed"] },
			});

			for (const ticket of activeTickets) {
				try {
					// Initialize SLA if missing
					if (
						!ticket.sla ||
						(!ticket.sla.responseTime && !ticket.sla.resolutionTime)
					) {
						await this.initializeSLA(ticket);
						continue; // Skip this round, will check on next interval
					}
					await this.checkTicketSLA(ticket);
				} catch (error) {
					console.error(`Error checking SLA for ticket ${ticket._id}:`, error);
					// Continue with other tickets
				}
			}
		} catch (error) {
			console.error("Error checking all tickets SLA:", error);
		}
	}

	async handleSLABreach(ticket, breachType) {
		try {
			// Update ticket with breach information
			ticket.history.push({
				action: "sla_breach",
				details: { breachType },
			});

			await ticket.save();

			// Create notification
			await this.notificationService.createSLABreachNotification(ticket);
		} catch (error) {
			console.error(
				`Error handling SLA breach for ticket ${ticket._id}:`,
				error
			);
		}
	}

	async escalateTicket(ticket) {
		try {
			if (ticket.status === "escalated") return;

			// Handle escalation directly instead of using ticketService
			ticket.status = "escalated";
			ticket.escalationLevel = (ticket.escalationLevel || 0) + 1;

			ticket.history.push({
				action: "escalated", // Valid enum value
				details: {
					reason: "SLA breach",
					previousLevel: ticket.escalationLevel - 1,
				},
			});

			await ticket.save();
			console.log(
				`Ticket ${ticket._id} escalated to level ${ticket.escalationLevel}`
			);

			// Optionally create notifications here
		} catch (error) {
			console.error(`Error escalating ticket ${ticket._id}:`, error);
		}
	}

	async getSLAConfig(priority, category) {
		const config = await SLAConfig.findOne({ priority, category });
		if (!config) {
			// Fall back to default configuration if specific one not found
			const defaultConfig = await SLAConfig.findOne({
				priority: 2,
				category: "general",
			});
			if (!defaultConfig) {
				// Create a very basic default if nothing found
				return {
					priority: priority || 2,
					category: category || "general",
					responseTime: 60, // 1 hour
					resolutionTime: 480, // 8 hours
				};
			}
			return defaultConfig;
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
