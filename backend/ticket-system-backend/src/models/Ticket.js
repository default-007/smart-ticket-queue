// src/models/Ticket.js
const mongoose = require("mongoose");

const ticketHistorySchema = new mongoose.Schema({
	action: {
		type: String,
		enum: [
			"created",
			"updated",
			"assigned",
			"reassigned",
			"escalated",
			"handover",
			"resolved",
			"closed",
			"sla_breach",
			"status_updated",
			"requeued",
		],
		required: true,
	},
	performedBy: {
		type: mongoose.Schema.Types.ObjectId,
		ref: "User",
	},
	timestamp: {
		type: Date,
		default: Date.now,
	},
	details: {
		type: mongoose.Schema.Types.Mixed,
	},
});

const slaSchema = new mongoose.Schema({
	responseTime: {
		deadline: Date,
		met: {
			type: Boolean,
			default: false,
		},
	},
	resolutionTime: {
		deadline: Date,
		met: {
			type: Boolean,
			default: false,
		},
	},
	escalationLevel: {
		type: Number,
		default: 0,
	},
	lastEscalation: Date,
});

const ticketSchema = new mongoose.Schema(
	{
		title: {
			type: String,
			required: [true, "Please provide ticket title"],
			trim: true,
		},
		description: {
			type: String,
			required: [true, "Please provide ticket description"],
			trim: true,
		},
		status: {
			type: String,
			enum: [
				"queued",
				"assigned",
				"in-progress",
				"resolved",
				"closed",
				"escalated",
			],
			default: "queued",
		},
		priority: {
			type: Number,
			required: true,
			enum: [1, 2, 3], // 1: High, 2: Medium, 3: Low
			default: 2,
		},
		category: {
			type: String,
			enum: ["technical", "billing", "general", "urgent"],
			default: "general",
		},
		dueDate: {
			type: Date,
			required: true,
		},
		estimatedHours: {
			type: Number,
			required: true,
			default: 1,
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
		department: {
			type: String,
			required: true,
			default: "general",
		},
		requiredSkills: [String],
		sla: {
			type: slaSchema,
			default: () => ({}),
		},
		escalationLevel: {
			type: Number,
			default: 0,
		},
		history: [ticketHistorySchema],
		firstResponseTime: Date,
		resolvedAt: Date,
		resolutionTime: Number, // in minutes
	},
	{
		timestamps: true,
	}
);

// Indexes
ticketSchema.index({ status: 1, priority: 1, createdAt: -1 });
ticketSchema.index({ assignedTo: 1, status: 1 });
ticketSchema.index({ createdBy: 1, status: 1 });
ticketSchema.index({ dueDate: 1 });
ticketSchema.index({ priority: 1, dueDate: 1 });
ticketSchema.index({ "sla.responseTime.deadline": 1 });
ticketSchema.index({ "sla.resolutionTime.deadline": 1 });

// Methods
ticketSchema.methods.isOverdue = function () {
	return (
		this.dueDate < new Date() &&
		this.status !== "resolved" &&
		this.status !== "closed"
	);
};

ticketSchema.methods.needsEscalation = function () {
	return (
		this.sla &&
		((this.sla.responseTime &&
			!this.sla.responseTime.met &&
			new Date() > this.sla.responseTime.deadline) ||
			(this.sla.resolutionTime &&
				!this.sla.resolutionTime.met &&
				new Date() > this.sla.resolutionTime.deadline))
	);
};

// Pre-save hook for SLA initialization
ticketSchema.pre("save", async function (next) {
	if (this.isNew && !this.sla?.responseTime?.deadline) {
		try {
			// Instead of requiring SLAService directly, calculate deadlines here
			const config = (await SLAConfig.findOne({
				priority: this.priority,
				category: this.category,
			})) || {
				responseTime: 60,
				resolutionTime: 480,
			};

			const now = new Date();
			this.sla = {
				responseTime: {
					deadline: new Date(now.getTime() + config.responseTime * 60000),
					met: false,
				},
				resolutionTime: {
					deadline: new Date(now.getTime() + config.resolutionTime * 60000),
					met: false,
				},
			};
		} catch (error) {
			console.error("Error initializing SLA for ticket:", error);
		}
	}
	next();
});

module.exports = mongoose.model("Ticket", ticketSchema);
