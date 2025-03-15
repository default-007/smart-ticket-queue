// services/notificationService.js
const Notification = require("../models/Notification");
const User = require("../models/User");
const mongoose = require("mongoose");

class NotificationService {
	async createNotification(data) {
		const notification = new Notification({
			type: data.type,
			message: data.message,
			recipient: data.recipient,
			ticket: data.ticket,
			metadata: data.metadata,
		});

		await notification.save();

		// Emit event for real-time notifications if WebSocket is implemented
		global.io?.to(data.recipient.toString()).emit("notification", notification);

		return notification;
	}

	async cleanupNotifications() {
		// Delete read notifications older than 30 days
		const thirtyDaysAgo = new Date();
		thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

		await Notification.deleteMany({
			read: true,
			createdAt: { $lt: thirtyDaysAgo },
		});

		// Mark unread notifications older than 60 days as read
		const sixtyDaysAgo = new Date();
		sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);

		await Notification.updateMany(
			{ read: false, createdAt: { $lt: sixtyDaysAgo } },
			{ $set: { read: true } }
		);
	}

	async getUnreadNotifications(userId) {
		return await Notification.find({
			recipient: userId,
			read: false,
		})
			.sort("-createdAt")
			.populate("ticket", "title status priority");
	}

	async markAsRead(notificationId, userId) {
		const notification = await Notification.findOneAndUpdate(
			{
				_id: notificationId,
				recipient: userId,
			},
			{ read: true },
			{ new: true }
		);

		if (!notification) {
			throw new Error("Notification not found");
		}

		return notification;
	}

	async markAllAsRead(userId) {
		await Notification.updateMany(
			{
				recipient: userId,
				read: false,
			},
			{ read: true }
		);
	}

	async deleteNotification(notificationId, userId) {
		const notification = await Notification.findOneAndDelete({
			_id: notificationId,
			recipient: userId,
		});

		if (!notification) {
			throw new Error("Notification not found");
		}
	}

	async getNotificationPreferences(userId) {
		const user = await User.findById(userId).select("notificationPreferences");
		return user.notificationPreferences;
	}

	async updateNotificationPreferences(userId, preferences) {
		const user = await User.findByIdAndUpdate(
			userId,
			{ notificationPreferences: preferences },
			{ new: true }
		);
		return user.notificationPreferences;
	}

	async createSLABreachNotification(ticket) {
		const recipients = await this.getSLABreachRecipients(ticket);

		const notifications = recipients.map((recipient) => ({
			type: "sla_breach",
			message: `SLA breach for ticket #${ticket._id}: ${ticket.title}`,
			recipient: recipient._id,
			ticket: ticket._id,
			metadata: {
				breachType: "resolution_time",
				ticketPriority: ticket.priority,
			},
		}));

		await Notification.insertMany(notifications);
	}

	async createTicketAssignmentNotification(ticket, agent) {
		await this.createNotification({
			type: "ticket_assigned",
			message: `New ticket assigned: ${ticket.title}`,
			recipient: agent._id,
			ticket: ticket._id,
			metadata: {
				priority: ticket.priority,
				dueDate: ticket.dueDate,
			},
		});
	}

	async createShiftEndingNotification(agent) {
		const activeTickets = await Ticket.find({
			_id: { $in: agent.activeTickets },
		});

		await this.createNotification({
			type: "shift_ending",
			message: `Your shift ends in 30 minutes. You have ${activeTickets.length} active tickets.`,
			recipient: agent._id,
			metadata: {
				activeTickets: activeTickets.map((t) => ({
					id: t._id,
					title: t.title,
					status: t.status,
				})),
			},
		});
	}

	async getSLABreachRecipients(ticket) {
		return await User.find({
			role: { $in: ["supervisor", "manager"] },
			department: ticket.department,
		});
	}

	async cleanupOldNotifications() {
		const thirtyDaysAgo = new Date();
		thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

		await Notification.deleteMany({
			createdAt: { $lt: thirtyDaysAgo },
			read: true,
		});
	}
}

module.exports = new NotificationService();
