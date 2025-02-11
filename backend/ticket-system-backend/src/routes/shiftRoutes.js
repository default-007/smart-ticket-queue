const express = require("express");
const router = express.Router();
const shiftController = require("../controllers/shiftController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");

router.use(auth);

router.post("/start", authorize(["agent"]), shiftController.startShift);
router.post("/:shiftId/end", authorize(["agent"]), shiftController.endShift);

router.post(
	"/:shiftId/breaks",
	authorize(["agent"]),
	shiftController.scheduleBreak
);
router.post(
	"/:shiftId/breaks/:breakId/start",
	authorize(["agent"]),
	shiftController.startBreak
);
router.post(
	"/:shiftId/breaks/:breakId/end",
	authorize(["agent"]),
	shiftController.endBreak
);

router.get(
	"/agent/:agentId",
	authorize(["admin", "agent"]),
	shiftController.getAgentShifts
);

module.exports = router;
