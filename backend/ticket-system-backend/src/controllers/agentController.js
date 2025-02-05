const asyncHandler = require("../utils/asyncHandler");
const agentService = require("../services/agentService");
const Agent = require("../models/Agent");

exports.getAgentByUserId = asyncHandler(async (req, res) => {
	const { userId } = req.params;

	const agent = await Agent.findOne({ user: userId });

	if (!agent) {
		res.status(404);
		throw new Error("Agent not found");
	}

	res.json({
		success: true,
		data: agent,
	});
});

exports.getAgentList = asyncHandler(async (req, res) => {
	const agents = await Agent.find();
	res.json({
		success: true,
		data: agents,
	});
});

exports.updateStatus = asyncHandler(async (req, res) => {
	const { id } = req.params;
	const { status } = req.body;

	const agent = await agentService.updateAgentStatus(id, status);

	res.json({
		success: true,
		data: agent,
	});
});

exports.getAvailableAgents = asyncHandler(async (req, res) => {
	const agents = await agentService.getAvailableAgents();

	res.json({
		success: true,
		count: agents.length,
		data: agents,
	});
});

exports.claimTicket = asyncHandler(async (req, res) => {
	const { agentId, ticketId } = req.params;

	const result = await agentService.claimTicket(agentId, ticketId);

	res.json({
		success: true,
		data: result,
	});
});

exports.updateShift = asyncHandler(async (req, res) => {
	const { id } = req.params;
	const shiftData = req.body;

	const agent = await agentService.updateShiftSchedule(id, shiftData);

	res.json({
		success: true,
		data: agent,
	});
});
