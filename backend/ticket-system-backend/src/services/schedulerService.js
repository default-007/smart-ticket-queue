const cron = require("node-cron");
const TicketService = require("./ticketService");
const WorkloadService = require("./workloadService");
const SLAService = require("./slaService");
const NotificationService = require("./notificationService");
const Agent = require("../models/Agent");

class SchedulerService {
	constructor() {
		this.setupScheduledTasks();
	}

	setupScheduledTasks() {
		// Process ticket queue every 5 minutes
		cron.schedule("*/5 * * * *", async () => {
			await this.processTicketQueue();
		});

		// Check SLA compliance every minute
		cron.schedule("* * * * *", async () => {
			await this.checkSLACompliance();
		});

		// Balance workload every 15 minutes
		cron.schedule("*/15 * * * *", async () => {
			await this.balanceWorkload();
		});

		// Check upcoming shifts every hour
		cron.schedule("0 * * * *", async () => {
			await this.checkUpcomingShifts();
		});

		// Clean up old notifications daily
		cron.schedule("0 0 * * *", async () => {
			await this.cleanupOldNotifications();
		});

		// Generate daily reports at midnight
		cron.schedule("0 0 * * *", async () => {
			await this.generateDailyReports();
		});
	}

	async processTicketQueue() {
		try {
			const queuedTickets = await Ticket.find({
				status: "queued",
				assignedTo: null,
			})
				.sort({ priority: 1, createdAt: 1 })
				.limit(100);

			if (queuedTickets.length === 0) return { processed: 0 };

			const ticketUpdates = [];
			const agentUpdates = [];
			const notifications = [];

			for (const ticket of queuedTickets) {
				// Process ticket logic...
				// Instead of await ticket.save(), collect updates
				ticketUpdates.push({
					updateOne: {
						filter: { _id: ticket._id },
						update: { $set: { status: "assigned", assignedTo: agent._id } },
					},
				});

				// Collect agent updates too
				agentUpdates.push({
					updateOne: {
						filter: { _id: agent._id },
						update: {
							$inc: { currentLoad: ticket.estimatedHours },
							$push: { activeTickets: ticket._id },
						},
					},
				});

				// And notifications
				notifications.push({
					type: "ticket_assigned",
					recipient: agent._id,
					ticket: ticket._id,
					message: `New ticket assigned: ${ticket.title}`,
				});
			}

			// Execute all updates in bulk
			if (ticketUpdates.length > 0) {
				await Ticket.bulkWrite(ticketUpdates);
			}

			if (agentUpdates.length > 0) {
				await Agent.bulkWrite(agentUpdates);
			}

			if (notifications.length > 0) {
				await Notification.insertMany(notifications);
			}

			return { processed: ticketUpdates.length };
		} catch (error) {
			logger.error(`Error processing queue: ${error.message}`);
			throw error;
		}
	}

	async checkSLACompliance() {
		try {
			console.log("Checking SLA compliance...");
			await SLAService.checkAllTicketsSLA();
		} catch (error) {
			console.error("Error checking SLA compliance:", error);
		}
	}

	async balanceWorkload() {
		try {
			console.log("Balancing workload...");
			await WorkloadService.rebalanceWorkload();
		} catch (error) {
			console.error("Error balancing workload:", error);
		}
	}

	async checkUpcomingShifts() {
		try {
			console.log("Checking upcoming shifts...");
			const now = new Date();
			const thirtyMinutesFromNow = new Date(now.getTime() + 30 * 60000);

			const agents = await Agent.find({
				"shift.end": {
					$gt: now,
					$lte: thirtyMinutesFromNow,
				},
				status: "online",
			});

			for (const agent of agents) {
				await NotificationService.createShiftEndingNotification(agent);
			}
		} catch (error) {
			console.error("Error checking upcoming shifts:", error);
		}
	}

	async cleanupOldNotifications() {
		try {
			console.log("Cleaning up old notifications...");
			await NotificationService.cleanupOldNotifications();
		} catch (error) {
			console.error("Error cleaning up notifications:", error);
		}
	}

	async generateDailyReports() {
		try {
			console.log("Generating daily reports...");
			const endDate = new Date();
			const startDate = new Date(endDate);
			startDate.setDate(startDate.getDate() - 1);

			const reports = await Promise.all([
				SLAService.getSLAMetrics(startDate, endDate),
				TicketService.getTicketMetrics(startDate, endDate),
				WorkloadService.getWorkloadSummary(),
			]);

			// Store reports or send them to relevant stakeholders
			// Implementation depends on specific requirements
		} catch (error) {
			console.error("Error generating daily reports:", error);
		}
	}

	// Method to schedule a specific task
	scheduleTask(cronExpression, task) {
		return cron.schedule(cronExpression, task);
	}

	// Method to schedule a one-time task
	scheduleOneTimeTask(timestamp, task) {
		const delay = timestamp - Date.now();
		if (delay <= 0) return;

		setTimeout(task, delay);
	}
}

module.exports = SchedulerService;
