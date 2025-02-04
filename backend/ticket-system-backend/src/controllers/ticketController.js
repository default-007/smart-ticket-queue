const asyncHandler = require("../utils/asyncHandler");
const ticketService = require("../services/ticketService");
const Ticket = require("../models/Ticket");

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
	const { status, assignedTo } = req.query;
	let query = {};

	if (status) query.status = status;
	if (assignedTo) query.assignedTo = assignedTo;

	const tickets = await Ticket.find(query)
		.populate("assignedTo", "name email status")
		.sort("-createdAt");

	res.json({
		success: true,
		count: tickets.length,
		data: tickets,
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
	const { status } = req.body;

	const ticket = await Ticket.findByIdAndUpdate(
		id,
		{ status },
		{ new: true, runValidators: true }
	).populate("assignedTo", "name email status");

	if (!ticket) {
		res.status(404);
		throw new Error("Ticket not found");
	}

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
