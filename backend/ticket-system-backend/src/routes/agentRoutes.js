// routes/agentRoutes.js
const express = require("express");
const router = express.Router();
const {
	updateStatus,
	getAvailableAgents,
	claimTicket,
	updateShift,
	getAgentByUserId,
	getAgentList,
} = require("../controllers/agentController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");
//const { checkPermission } = require("../middleware/auth");

router.use(auth);

// Only admins and agents can access agent routes
router.get("/", authorize(["admin", "agent"]), getAgentList);
router.get("/user/:userId", authorize(["admin", "agent"]), getAgentByUserId);
router.get("/available", authorize(["admin", "agent"]), getAvailableAgents);
router.put("/:id/status", authorize(["admin", "agent"]), updateStatus);
router.put("/:id/shift", authorize(["admin", "agent"]), updateShift);
router.post(
	"/:agentId/claim/:ticketId",
	authorize(["admin", "agent"]),
	claimTicket
);

module.exports = router;
