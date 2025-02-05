// routes/ticketRoutes.js
const express = require("express");
const router = express.Router();
const {
	createTicket,
	getTickets,
	getQueuedTickets,
	updateTicketStatus,
	processQueue,
} = require("../controllers/ticketController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");
const { checkPermission } = require("../middleware/checkPermission");

router.use(auth);

// Routes with role-based authorization
router.post("/", authorize(["admin", "user"]), createTicket);
router.get("/", authorize(["admin", "agent"]), getTickets);
router.get("/queue", authorize(["admin", "agent"]), getQueuedTickets);
router.put("/:id/status", authorize(["admin", "agent"]), updateTicketStatus);
router.post("/process-queue", authorize("admin"), processQueue);

module.exports = router;
