const express = require("express");
const router = express.Router();
const {
	updateStatus,
	getAvailableAgents,
	claimTicket,
	updateShift,
	getAgentByUserId,
} = require("../controllers/agentController");
const auth = require("../middleware/auth");

router.use(auth); // Protect all routes

router.get("/user/:userId", getAgentByUserId);
router.get("/available", getAvailableAgents);
router.put("/:id/status", updateStatus);
router.put("/:id/shift", updateShift);
router.post("/:agentId/claim/:ticketId", claimTicket);

module.exports = router;
