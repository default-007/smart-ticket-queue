const mongoose = require("mongoose");

const shiftSchema = new mongoose.Schema({
	start: {
		type: Date,
		required: true,
	},
	end: {
		type: Date,
		required: true,
	},
	timezone: {
		type: String,
		default: "UTC",
	},
});

const agentSchema = new mongoose.Schema(
	{
		name: {
			type: String,
			required: [true, "Please provide agent name"],
			trim: true,
		},
		email: {
			type: String,
			required: [true, "Please provide agent email"],
			unique: true,
			trim: true,
			lowercase: true,
		},
		status: {
			type: String,
			enum: ["online", "offline", "busy"],
			default: "offline",
		},
		currentTicket: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Ticket",
			default: null,
		},
		shift: shiftSchema,
		maxTickets: {
			type: Number,
			default: 5,
		},
		currentLoad: {
			type: Number,
			default: 0,
		},
		skills: [
			{
				type: String,
				trim: true,
			},
		],
		department: {
			type: String,
			required: true,
			trim: true,
		},
	},
	{
		timestamps: true,
	}
);

// Index for faster querying
agentSchema.index({ status: 1, currentLoad: 1 });

module.exports = mongoose.model("Agent", agentSchema);
