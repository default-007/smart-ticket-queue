const asyncHandler = require("../utils/asyncHandler");
const agentService = require("../services/agentService");
const Agent = require("../models/Agent");
const User = require("../models/User");

exports.getAgentByUserId = asyncHandler(async (req, res) => {
	const { userId } = req.params;

	let agent = await Agent.findOne({ user: userId });

	// Auto-create agent record if it doesn't exist
	if (!agent) {
		const user = await User.findById(userId);
		if (!user) {
			res.status(404);
			throw new Error("User not found");
		}

		// Verify user has agent role
		if (user.role !== "agent") {
			res.status(400);
			throw new Error("User is not an agent");
		}

		// Try to find an agent with the same email
		agent = await Agent.findOne({ email: user.email });

		if (agent) {
			// If found, update the user ID
			agent.user = userId;
			await agent.save();
		} else {
			try {
				// If not found, create a new agent
				agent = await Agent.create({
					name: user.name,
					email: user.email,
					status: "offline",
					user: userId,
					department: "Support",
					skills: [],
					maxTickets: 5,
					currentLoad: 0,
					activeTickets: [],
					shift: {
						start: new Date(),
						end: new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
						timezone: "UTC",
					},
				});
			} catch (err) {
				if (err.code === 11000) {
					// Handle duplicate key error more gracefully
					res.status(409);
					throw new Error(
						"An agent with this email already exists but is not linked to your account. Please contact an administrator."
					);
				}
				throw err;
			}
		}
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
	// If agentService doesn't have getAvailableAgents, implement directly
	const availableAgents = await Agent.find({
		status: "online",
		currentLoad: { $lt: 8 }, // Agents with less than 8 hours of current load
		// Add any other conditions for availability
	});

	res.json({
		success: true,
		count: availableAgents.length,
		data: availableAgents,
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
