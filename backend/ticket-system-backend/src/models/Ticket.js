const mongoose = require("mongoose");

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
			enum: ["online", "offline", "busy", "break"],
			default: "offline",
		},
		currentTicket: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Ticket",
			default: null,
		},
		activeTickets: [
			{
				type: mongoose.Schema.Types.ObjectId,
				ref: "Ticket",
			},
		],
		shift: {
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
			breaks: [
				{
					start: Date,
					end: Date,
					type: {
						type: String,
						enum: ["lunch", "short-break"],
					},
				},
			],
		},
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
				name: String,
				level: {
					type: Number,
					min: 1,
					max: 5,
				},
			},
		],
		department: {
			type: String,
			required: true,
			trim: true,
		},
		teams: [
			{
				type: String,
				trim: true,
			},
		],
		specializations: [
			{
				type: String,
				trim: true,
			},
		],
		performance: {
			averageResolutionTime: Number,
			ticketsResolved: Number,
			customerSatisfaction: Number,
			slaComplianceRate: Number,
		},
		availability: {
			nextAvailableSlot: Date,
			workingHours: {
				type: Map,
				of: {
					start: String,
					end: String,
					isWorkingDay: Boolean,
				},
			},
		},
	},
	{
		timestamps: true,
	}
);

// Indexes
agentSchema.index({ status: 1, currentLoad: 1 });
agentSchema.index({ department: 1, "skills.name": 1 });
agentSchema.index({ "shift.start": 1, "shift.end": 1 });

// Methods
agentSchema.methods.isAvailable = function () {
	const now = new Date();
	return (
		this.status === "online" &&
		this.currentLoad < this.maxTickets &&
		now > this.shift.start &&
		now < this.shift.end &&
		!this.isOnBreak()
	);
};

agentSchema.methods.isOnBreak = function () {
	const now = new Date();
	return this.shift.breaks.some(
		(breakPeriod) => now >= breakPeriod.start && now <= breakPeriod.end
	);
};

agentSchema.methods.canHandleTicket = function (ticket) {
	const estimatedEndTime = new Date(
		Date.now() + ticket.estimatedHours * 60 * 60 * 1000
	);
	return (
		this.isAvailable() &&
		estimatedEndTime <= this.shift.end &&
		this.hasRequiredSkills(ticket)
	);
};

agentSchema.methods.hasRequiredSkills = function (ticket) {
	// Check if agent has the required skills for the ticket
	return ticket.requiredSkills.every((requiredSkill) =>
		this.skills.some(
			(skill) =>
				skill.name === requiredSkill.name && skill.level >= requiredSkill.level
		)
	);
};

module.exports = mongoose.model("Agent", agentSchema);
