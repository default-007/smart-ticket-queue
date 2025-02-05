const mongoose = require("mongoose");

const slaConfigSchema = new mongoose.Schema(
	{
		priority: {
			type: Number,
			required: true,
			enum: [1, 2, 3],
		},
		category: {
			type: String,
			required: true,
			enum: ["technical", "billing", "general", "urgent"],
		},
		responseTime: {
			type: Number,
			required: true,
			min: 1,
			default: 60, // minutes
		},
		resolutionTime: {
			type: Number,
			required: true,
			min: 1,
			default: 480, // minutes (8 hours)
		},
		escalationRules: [
			{
				level: Number,
				threshold: Number, // minutes after previous level
				notifyRoles: [String],
			},
		],
	},
	{
		timestamps: true,
	}
);

// Compound index for priority and category
slaConfigSchema.index({ priority: 1, category: 1 }, { unique: true });

module.exports = mongoose.model("SLAConfig", slaConfigSchema);
