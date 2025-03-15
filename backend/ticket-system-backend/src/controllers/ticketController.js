const asyncHandler = require("../utils/asyncHandler");
const ticketService = require("../services/ticketService");
const Ticket = require("../models/Ticket");
const Agent = require("../models/Agent");

exports.createTicket = asyncHandler(async (req, res) => {
	const ticket = await ticketService.createTicket({
		...req.body,
		createdBy: req.user.id, // Assuming user info is added by auth middleware
	});

	res.status(201).json({
		success: true,
		data: ticket,
	});
});

exports.getTickets = asyncHandler(async (req, res) => {
	// Extract query parameters from request
	const { status, assignedTo, priority, department } = req.query;

	// Build query object based on provided parameters
	let query = {};

	if (status) query.status = status;
	if (assignedTo) query.assignedTo = assignedTo;
	if (priority) query.priority = parseInt(priority);
	if (department) query.department = department;

	// Add user role-based filtering
	if (req.user.role === "user") {
		// Regular users can only see their own tickets
		query.createdBy = req.user.id;
	} else if (req.user.role === "agent" && !assignedTo) {
		// Agents see tickets assigned to them by default unless otherwise specified
		query.assignedTo = req.user.id;
	}
	// Admins can see all tickets based on other filters

	// Execute the query with pagination
	const page = parseInt(req.query.page) || 1;
	const limit = parseInt(req.query.limit) || 20;
	const skip = (page - 1) * limit;

	const tickets = await Ticket.find(query)
		.populate("assignedTo", "name email status")
		.populate("createdBy", "name email")
		.sort("-createdAt")
		.skip(skip)
		.limit(limit);

	// Get total count for pagination
	const total = await Ticket.countDocuments(query);

	res.json({
		success: true,
		count: tickets.length,
		total,
		pages: Math.ceil(total / limit),
		currentPage: page,
		data: tickets,
	});
});

exports.getTicketById = asyncHandler(async (req, res) => {
	const ticket = await Ticket.findById(req.params.id).populate(
		"assignedTo",
		"name email status"
	);

	if (!ticket) {
		res.status(404);
		throw new Error("Ticket not found");
	}

	res.json({
		success: true,
		data: ticket,
	});
});

exports.getQueuedTickets = asyncHandler(async (req, res) => {
	const tickets = await ticketService.getTicketsByStatus("queued");

	res.json({
		success: true,
		count: tickets.length,
		data: tickets,
	});
});

exports.updateTicketStatus = asyncHandler(async (req, res) => {
	const { id } = req.params;
	const { status, agentId } = req.body;

	let ticket = await Ticket.findById(id);
	if (!ticket) {
		res.status(404);
		throw new Error("Ticket not found");
	}

	ticket.status = status;

	// If status is being set to "assigned" and an agentId is provided, assign the agent
	if (status === "assigned" && agentId) {
		const agent = await Agent.findById(agentId);
		if (!agent) {
			res.status(400);
			throw new Error("Agent not found");
		}

		ticket.assignedTo = agent._id;

		// Update agent's workload
		agent.activeTickets = agent.activeTickets || [];
		agent.activeTickets.push(ticket._id);
		agent.currentLoad += ticket.estimatedHours;
		await agent.save();
	}

	// Add to history
	ticket.history.push({
		action: "status_updated",
		performedBy: req.user.id,
		details: {
			oldStatus: ticket.status,
			newStatus: status,
			assignedTo: agentId || null,
		},
	});

	await ticket.save();

	// Return populated ticket data
	ticket = await Ticket.findById(id).populate(
		"assignedTo",
		"name email status"
	);

	res.json({
		success: true,
		data: ticket,
	});
});

exports.processQueue = asyncHandler(async (req, res) => {
	const results = await ticketService.processQueue();

	res.json({
		success: true,
		data: results,
	});
});

exports.resolveEscalation = asyncHandler(async (req, res) => {
	const { id } = req.params;
	const ticket = await Ticket.findById(id);

	if (!ticket) {
		res.status(404);
		throw new Error("Ticket not found");
	}

	ticket.escalationLevel = 0;
	if (ticket.status === "escalated") {
		ticket.status = "in-progress";
	}

	ticket.history.push({
		action: "status_updated", // Using valid enum value
		performedBy: req.user.id,
		details: {
			escalationResolved: true,
			previousLevel: ticket.escalationLevel,
		},
	});

	await ticket.save();

	res.json({
		success: true,
		data: ticket,
	});
});
