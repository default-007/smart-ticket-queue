const mongoose = require("mongoose");

const ticketSchema = new mongoose.Schema(
	{
		title: {
			type: String,
			required: [true, "Please provide a ticket title"],
			trim: true,
		},
		description: {
			type: String,
			required: [true, "Please provide a ticket description"],
		},
		status: {
			type: String,
			enum: ["queued", "assigned", "in-progress", "resolved", "closed"],
			default: "queued",
		},
		priority: {
			type: Number,
			enum: [1, 2, 3], // 1: High, 2: Medium, 3: Low
			default: 2,
		},
		dueDate: {
			type: Date,
			required: [true, "Please provide a due date"],
		},
		estimatedHours: {
			type: Number,
			required: [true, "Please provide estimated hours"],
		},
		assignedTo: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Agent",
			default: null,
		},
		createdBy: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "User",
			required: true,
		},
	},
	{
		timestamps: true,
	}
);

// Index for faster querying
ticketSchema.index({ status: 1, assignedTo: 1, createdAt: 1 });

module.exports = mongoose.model("Ticket", ticketSchema);
