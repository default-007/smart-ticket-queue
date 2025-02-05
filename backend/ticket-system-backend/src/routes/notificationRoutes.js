const express = require("express");
const router = express.Router();
const {
	getUnreadNotifications,
	markAsRead,
	markAllAsRead,
	deleteNotification,
	getNotificationPreferences,
	updateNotificationPreferences,
} = require("../controllers/notificationController");
const auth = require("../middleware/auth");

router.use(auth);

router.get("/unread", getUnreadNotifications);
router.put("/:notificationId/read", markAsRead);
router.put("/mark-all-read", markAllAsRead);
router.delete("/:notificationId", deleteNotification);
router.get("/preferences", getNotificationPreferences);
router.put("/preferences", updateNotificationPreferences);

module.exports = router;
