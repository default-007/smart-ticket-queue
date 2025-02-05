// controllers/slaController.js
const asyncHandler = require("../utils/asyncHandler");
const SLAService = require("../services/slaService");
const authorize = require("../middleware/authorize");

exports.getSLAMetrics = asyncHandler(async (req, res) => {
	const { startDate, endDate, department } = req.query;

	const metrics = await SLAService.getSLAMetrics(
		new Date(startDate),
		new Date(endDate),
		department
	);

	res.json({
		success: true,
		data: metrics,
	});
});

exports.getSLAConfig = asyncHandler(async (req, res) => {
	const { priority, category } = req.params;
	const config = await SLAService.getSLAConfig(parseInt(priority), category);

	res.json({
		success: true,
		data: config,
	});
});

exports.updateSLAConfig = [
	authorize("admin"),
	asyncHandler(async (req, res) => {
		const { priority, category } = req.params;
		const { responseTime, resolutionTime } = req.body;

		const config = await SLAService.updateSLAConfig(
			parseInt(priority),
			category,
			{ responseTime, resolutionTime }
		);

		res.json({
			success: true,
			data: config,
		});
	}),
];

exports.checkTicketSLA = asyncHandler(async (req, res) => {
	const { ticketId } = req.params;
	const status = await SLAService.checkTicketSLA(ticketId);

	res.json({
		success: true,
		data: status,
	});
});
