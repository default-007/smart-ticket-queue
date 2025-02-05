// controllers/notificationController.js
const asyncHandler = require("../utils/asyncHandler");
const NotificationService = require("../services/notificationService");

exports.getUnreadNotifications = asyncHandler(async (req, res) => {
	const notifications = await NotificationService.getUnreadNotifications(
		req.user.id
	);

	res.json({
		success: true,
		count: notifications.length,
		data: notifications,
	});
});

exports.markAsRead = asyncHandler(async (req, res) => {
	const { notificationId } = req.params;
	const notification = await NotificationService.markAsRead(
		notificationId,
		req.user.id
	);

	res.json({
		success: true,
		data: notification,
	});
});

exports.markAllAsRead = asyncHandler(async (req, res) => {
	await NotificationService.markAllAsRead(req.user.id);

	res.json({
		success: true,
		message: "All notifications marked as read",
	});
});

exports.deleteNotification = asyncHandler(async (req, res) => {
	const { notificationId } = req.params;
	await NotificationService.deleteNotification(notificationId, req.user.id);

	res.json({
		success: true,
		message: "Notification deleted",
	});
});

exports.getNotificationPreferences = asyncHandler(async (req, res) => {
	const preferences = await NotificationService.getNotificationPreferences(
		req.user.id
	);

	res.json({
		success: true,
		data: preferences,
	});
});

exports.updateNotificationPreferences = asyncHandler(async (req, res) => {
	const preferences = await NotificationService.updateNotificationPreferences(
		req.user.id,
		req.body
	);

	res.json({
		success: true,
		data: preferences,
	});
});
