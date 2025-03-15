// controllers/slaController.js
const asyncHandler = require("../utils/asyncHandler");
const SLAConfig = require("../models/SLAConfig");
const Ticket = require("../models/Ticket");

exports.getSLAMetrics = asyncHandler(async (req, res) => {
	const { startDate, endDate, department } = req.query;

	const match = {
		createdAt: {
			$gte: new Date(startDate),
			$lte: new Date(endDate),
		},
	};

	if (department) {
		match.department = department;
	}

	const metrics = await Ticket.aggregate([
		{ $match: match },
		{
			$group: {
				_id: null,
				totalTickets: { $sum: 1 },
				responseSLABreaches: {
					$sum: {
						$cond: [
							{
								$and: [
									{ $eq: ["$sla.responseTime.met", false] },
									{ $lt: ["$sla.responseTime.deadline", new Date()] },
								],
							},
							1,
							0,
						],
					},
				},
				resolutionSLABreaches: {
					$sum: {
						$cond: [
							{
								$and: [
									{ $eq: ["$sla.resolutionTime.met", false] },
									{ $lt: ["$sla.resolutionTime.deadline", new Date()] },
								],
							},
							1,
							0,
						],
					},
				},
				averageResponseTime: {
					$avg: {
						$ifNull: ["$firstResponseTime", null],
					},
				},
				averageResolutionTime: {
					$avg: {
						$ifNull: ["$resolutionTime", null],
					},
				},
				slaComplianceRate: {
					$avg: {
						$cond: [
							{
								$and: [
									{ $eq: ["$sla.responseTime.met", true] },
									{ $eq: ["$sla.resolutionTime.met", true] },
								],
							},
							1,
							0,
						],
					},
				},
			},
		},
		{
			$project: {
				_id: 0,
				totalTickets: 1,
				responseSLABreaches: 1,
				resolutionSLABreaches: 1,
				averageResponseTime: {
					$cond: [
						{ $ne: ["$averageResponseTime", null] },
						{ $divide: ["$averageResponseTime", 60000] }, // Convert to minutes
						null,
					],
				},
				averageResolutionTime: {
					$cond: [
						{ $ne: ["$averageResolutionTime", null] },
						{ $divide: ["$averageResolutionTime", 60000] }, // Convert to minutes
						null,
					],
				},
				slaComplianceRate: {
					$multiply: ["$slaComplianceRate", 100],
				},
			},
		},
	]);

	res.json({
		success: true,
		data: metrics[0] || {
			totalTickets: 0,
			responseSLABreaches: 0,
			resolutionSLABreaches: 0,
			averageResponseTime: null,
			averageResolutionTime: null,
			slaComplianceRate: 0,
		},
	});
});

exports.getSLAConfig = asyncHandler(async (req, res) => {
	/* const { priority, category } = req.params;
	const config = await SLAService.getSLAConfig(parseInt(priority), category);

	res.json({
		success: true,
		data: config,
	}); */
	try {
		const configs = await SLAConfig.find();
		res.json({
			success: true,
			data: configs,
		});
	} catch (error) {
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.updateSLAConfig = asyncHandler(async (req, res) => {
	const { priority, category } = req.params;
	const updateData = req.body;

	try {
		const config = await SLAConfig.findOneAndUpdate(
			{ priority: parseInt(priority), category },
			updateData,
			{ new: true, runValidators: true }
		);

		if (!config) {
			return res.status(404).json({
				success: false,
				message: "SLA configuration not found",
			});
		}

		res.json({
			success: true,
			data: config,
		});
	} catch (error) {
		console.error("Error updating SLA config:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.checkTicketSLA = asyncHandler(async (req, res) => {
	const { ticketId } = req.params;

	try {
		const ticket = await Ticket.findById(ticketId);

		if (!ticket) {
			return res.status(404).json({
				success: false,
				message: "Ticket not found",
			});
		}

		const slaStatus = {
			responseTimeMet: ticket.sla?.responseTime?.met || false,
			resolutionTimeMet: ticket.sla?.resolutionTime?.met || false,
			responseDeadline: ticket.sla?.responseTime?.deadline,
			resolutionDeadline: ticket.sla?.resolutionTime?.deadline,
		};

		res.json({
			success: true,
			data: slaStatus,
		});
	} catch (error) {
		console.error("Error checking ticket SLA:", error);
		res.status(500).json({
			success: false,
			message: error.message,
		});
	}
});

exports.getSLATrends = asyncHandler(async (req, res) => {
	const { period = "weekly" } = req.query;

	let groupBy = {
		year: { $year: "$createdAt" },
		week: { $week: "$createdAt" },
	};

	if (period === "monthly") {
		groupBy = {
			year: { $year: "$createdAt" },
			month: { $month: "$createdAt" },
		};
	} else if (period === "daily") {
		groupBy = {
			year: { $year: "$createdAt" },
			month: { $month: "$createdAt" },
			day: { $dayOfMonth: "$createdAt" },
		};
	}

	const trends = await Ticket.aggregate([
		{
			$group: {
				_id: groupBy,
				totalTickets: { $sum: 1 },
				slaBreaches: {
					$sum: {
						$cond: [
							{
								$or: [
									{ $eq: ["$sla.responseTime.met", false] },
									{ $eq: ["$sla.resolutionTime.met", false] },
								],
							},
							1,
							0,
						],
					},
				},
			},
		},
		{ $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1, "_id.week": 1 } },
	]);

	res.json({
		success: true,
		data: trends,
	});
});
