const mongoose = require("mongoose");

const breakSchema = new mongoose.Schema({
	type: {
		type: String,
		enum: ["lunch", "short-break", "training", "meeting"],
		required: true,
	},
	start: Date,
	end: Date,
	status: {
		type: String,
		enum: ["scheduled", "in-progress", "completed", "cancelled"],
		default: "scheduled",
	},
});

const shiftSchema = new mongoose.Schema(
	{
		agent: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Agent",
			required: true,
		},
		start: {
			type: Date,
			required: true,
		},
		end: {
			type: Date,
			required: true,
		},
		status: {
			type: String,
			enum: ["scheduled", "in-progress", "completed"],
			default: "scheduled",
		},
		breaks: [breakSchema],
		timezone: {
			type: String,
			default: "UTC",
		},
	},
	{
		timestamps: true,
	}
);

module.exports = mongoose.model("Shift", shiftSchema);
