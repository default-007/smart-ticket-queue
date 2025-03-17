const asyncHandler = require("../utils/asyncHandler");
const ShiftService = require("../services/shiftService");
const Shift = require("../models/Shift");
const Agent = require("../models/Agent");

exports.startShift = asyncHandler(async (req, res) => {
	const shift = await ShiftService.startShift(req.user.id);
	res.status(201).json({
		success: true,
		data: shift,
	});
});

exports.endShift = asyncHandler(async (req, res) => {
	const { shiftId } = req.params;
	const shift = await ShiftService.endShift(shiftId);
	res.json({
		success: true,
		data: shift,
	});
});

exports.scheduleBreak = asyncHandler(async (req, res) => {
	const { shiftId } = req.params;
	const breakData = req.body;
	const shift = await ShiftService.scheduleBreak(shiftId, breakData);
	res.status(201).json({
		success: true,
		data: shift,
	});
});

exports.startBreak = asyncHandler(async (req, res) => {
	const { shiftId, breakId } = req.params;
	const shift = await ShiftService.startBreak(shiftId, breakId);
	res.json({
		success: true,
		data: shift,
	});
});

exports.endBreak = asyncHandler(async (req, res) => {
	const { shiftId, breakId } = req.params;
	const shift = await ShiftService.endBreak(shiftId, breakId);
	res.json({
		success: true,
		data: shift,
	});
});

exports.getAgentShifts = asyncHandler(async (req, res) => {
	const { agentId } = req.params;
	const { startDate, endDate, status } = req.query;

	// Build query object
	const query = { agent: agentId };

	if (startDate) {
		query.start = { $gte: new Date(startDate) };
	}

	if (endDate) {
		query.end = { $lte: new Date(endDate) };
	}

	if (status) {
		query.status = status;
	}

	// Find shifts for the agent
	const shifts = await Shift.find(query)
		.sort({ start: -1 })
		.populate("agent", "name email department");

	res.json({
		success: true,
		count: shifts.length,
		data: shifts,
	});
});

exports.getCurrentShift = asyncHandler(async (req, res) => {
	const { agentId } = req.params;
	const now = new Date();

	// Find current shift (where now is between start and end times, and status is in-progress)
	const currentShift = await Shift.findOne({
		agent: agentId,
		start: { $lte: now },
		end: { $gte: now },
		status: "in-progress",
	}).populate("agent", "name email department");

	if (!currentShift) {
		res.status(404);
		throw new Error("No active shift found for this agent");
	}

	res.json({
		success: true,
		data: currentShift,
	});
});

exports.scheduleShift = asyncHandler(async (req, res) => {
	const { shiftId } = req.params;
	const shiftData = req.body;
	const shift = await ShiftService.scheduleShift(shiftId, shiftData);
	res.status(201).json({
		success: true,
		data: shift,
	});
});
