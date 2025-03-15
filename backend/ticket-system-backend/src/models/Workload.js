// src/models/Workload.js
const mongoose = require("mongoose");

const workloadSchema = new mongoose.Schema(
	{
		agent: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Agent",
			required: true,
		},
		currentLoad: {
			type: Number,
			default: 0,
		},
		maxLoad: {
			type: Number,
			default: 8, // standard 8-hour workday
		},
		activeTickets: [
			{
				type: mongoose.Schema.Types.ObjectId,
				ref: "Ticket",
			},
		],
		queuedTickets: [
			{
				type: mongoose.Schema.Types.ObjectId,
				ref: "Ticket",
			},
		],
		skills: [
			{
				name: String,
				level: {
					type: Number,
					min: 1,
					max: 5,
				},
			},
		],
		nextAvailableSlot: Date,
	},
	{
		timestamps: true,
	}
);

// Add indexes for better query performance
workloadSchema.index({ agent: 1 });
workloadSchema.index({ currentLoad: 1 });

// Create the model
const Workload = mongoose.model("Workload", workloadSchema);

// Export the model
module.exports = Workload;
