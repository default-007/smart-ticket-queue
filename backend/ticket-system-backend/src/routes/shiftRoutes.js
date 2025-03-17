const express = require("express");
const router = express.Router();
const shiftController = require("../controllers/shiftController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");

router.use(auth);

router.get(
	"/agent/:agentId",
	authorize(["admin", "agent"]),
	shiftController.getAgentShifts
);

// Get current shift for an agent
router.get(
	"/current/:agentId",
	authorize(["admin", "agent"]),
	shiftController.getCurrentShift
);

// Start a shift
router.post("/start", authorize(["agent"]), shiftController.startShift);

// End a shift
router.put("/:shiftId/end", authorize(["agent"]), shiftController.endShift);

// Schedule a break during a shift
router.post(
	"/:shiftId/breaks",
	authorize(["agent"]),
	shiftController.scheduleBreak
);

// Start a break
router.put(
	"/:shiftId/breaks/:breakId/start",
	authorize(["agent"]),
	shiftController.startBreak
);

// End a break
router.put(
	"/:shiftId/breaks/:breakId/end",
	authorize(["agent"]),
	shiftController.endBreak
);

// Schedule a future shift
router.post(
	"/schedule",
	authorize(["admin", "agent"]),
	shiftController.scheduleShift
);

module.exports = router;
