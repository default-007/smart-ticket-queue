const express = require("express");
const router = express.Router();
const {
	getWorkloadMetrics,
	getAgentWorkloads,
	getTeamCapacities,
	rebalanceWorkload,
	getWorkloadPredictions,
	optimizeAssignments,
} = require("../controllers/workloadController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");

router.use(auth);

// Workload metrics (admin access)
router.get("/metrics", authorize("admin"), getWorkloadMetrics);

// Agent workloads (admin access)
router.get("/agents", authorize("admin"), getAgentWorkloads);

// Team capacities (admin access)
router.get("/teams", authorize("admin"), getTeamCapacities);

// Workload rebalancing (admin access)
router.post("/rebalance", authorize("admin"), rebalanceWorkload);

// Workload predictions (admin access)
router.get("/predictions", authorize("admin"), getWorkloadPredictions);

// Optimize ticket assignments (admin access)
router.post("/optimize", authorize("admin"), optimizeAssignments);

module.exports = router;

module.exports = router;
