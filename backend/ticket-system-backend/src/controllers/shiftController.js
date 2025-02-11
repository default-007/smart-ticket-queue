const asyncHandler = require("../utils/asyncHandler");
const ShiftService = require("../services/shiftService");

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

	const shifts = await ShiftService.getAgentShifts(agentId, {
		startDate,
		endDate,
		status,
	});

	res.json({
		success: true,
		count: shifts.length,
		data: shifts,
	});
});
