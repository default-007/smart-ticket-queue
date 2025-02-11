const asyncHandler = require("../utils/asyncHandler");
const WorkloadService = require("../services/workloadService");

exports.redistributeWorkload = asyncHandler(async (req, res) => {
	await WorkloadService.redistributeWorkload();
	res.json({
		success: true,
		message: "Workload redistributed successfully",
	});
});

exports.getWorkloadMetrics = asyncHandler(async (req, res) => {
	const metrics = await WorkloadService.getWorkloadMetrics();
	res.json({
		success: true,
		data: metrics[0] || {},
	});
});
