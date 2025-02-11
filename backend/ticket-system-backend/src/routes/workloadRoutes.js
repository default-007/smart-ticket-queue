const express = require("express");
const router = express.Router();
const workloadController = require("../controllers/workloadController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");

router.use(auth);

router.post(
	"/redistribute",
	authorize(["admin"]),
	workloadController.redistributeWorkload
);
router.get(
	"/metrics",
	authorize(["admin"]),
	workloadController.getWorkloadMetrics
);

module.exports = router;
