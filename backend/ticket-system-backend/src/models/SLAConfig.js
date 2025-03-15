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
				level: {
					type: Number,
					required: true,
				},
				threshold: {
					type: Number,
					required: true,
				},
				notifyRoles: {
					type: [String],
					default: ["supervisor", "admin"],
				},
			},
		],
	},
	{
		timestamps: true,
	}
);

// Create default SLA configurations if none exist
slaConfigSchema.statics.createDefaultConfigs = async function () {
	const existingConfigs = await this.countDocuments();
	if (existingConfigs === 0) {
		const defaultConfigs = [
			// High Priority Configs
			{
				priority: 1,
				category: "urgent",
				responseTime: 30,
				resolutionTime: 120,
				escalationRules: [
					{
						level: 1,
						threshold: 30,
						notifyRoles: ["admin"],
					},
					{
						level: 2,
						threshold: 60,
						notifyRoles: ["admin"],
					},
				],
			},
			{
				priority: 1,
				category: "technical",
				responseTime: 45,
				resolutionTime: 240,
				escalationRules: [
					{
						level: 1,
						threshold: 45,
						notifyRoles: ["admin"],
					},
					{
						level: 2,
						threshold: 90,
						notifyRoles: ["admin"],
					},
				],
			},
			// Medium Priority Configs
			{
				priority: 2,
				category: "billing",
				responseTime: 120,
				resolutionTime: 480,
				escalationRules: [
					{
						level: 1,
						threshold: 120,
						notifyRoles: ["admin"],
					},
				],
			},
			{
				priority: 2,
				category: "general",
				responseTime: 240,
				resolutionTime: 720,
				escalationRules: [
					{
						level: 1,
						threshold: 240,
						notifyRoles: ["admin"],
					},
				],
			},
			// Low Priority Configs
			{
				priority: 3,
				category: "general",
				responseTime: 480,
				resolutionTime: 1440,
				escalationRules: [],
			},
		];

		await this.create(defaultConfigs);
		console.log("Default SLA configurations created");
	}
};

// Compound index for unique priority and category combination
slaConfigSchema.index({ priority: 1, category: 1 }, { unique: true });

const SLAConfig = mongoose.model("SLAConfig", slaConfigSchema);

// Create default configs when the model is first loaded
SLAConfig.createDefaultConfigs().catch((err) => {
	console.error("Error creating default SLA configs:", err);
});

module.exports = SLAConfig;
