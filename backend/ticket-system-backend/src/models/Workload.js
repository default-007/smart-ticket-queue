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
