// routes/ticketRoutes.js
const express = require("express");
const router = express.Router();
const {
	createTicket,
	getTickets,
	getTicketById,
	getQueuedTickets,
	updateTicketStatus,
	processQueue,
	resolveEscalation,
} = require("../controllers/ticketController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");
const { checkPermission } = require("../middleware/checkPermission");

router.use(auth);

// Routes with role-based authorization
router.post("/", authorize(["admin", "agent", "user"]), createTicket);
router.get("/", authorize("admin", "agent"), getTickets);
router.get("/queue", authorize(["admin", "agent"]), getQueuedTickets);
router.get("/:id", authorize(["admin", "agent", "user"]), getTicketById);
router.put("/:id/status", authorize(["admin", "agent"]), updateTicketStatus);
router.post("/process-queue", authorize("admin"), processQueue);
router.put("/:id/resolve-escalation", authorize(["admin"]), resolveEscalation);
/* router.put(
	"/:id/resolve-escalation",
	authorize(["admin"]),
	ticketController.resolveEscalation
); */

module.exports = router;
