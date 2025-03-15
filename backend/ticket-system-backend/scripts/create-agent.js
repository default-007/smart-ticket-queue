// create-agent.js
const mongoose = require("mongoose");
const User = require("../src/models/User");
const Agent = require("../src/models/Agent");
require("dotenv").config();

mongoose
	.connect(process.env.MONGODB_URI)
	.then(() => {
		console.log("Connected to MongoDB");
		createAgents();
	})
	.catch((err) => {
		console.error("MongoDB connection error:", err);
		process.exit(1);
	});

async function createAgents() {
	try {
		// Find the agent users
		const agentUsers = await User.find({ role: "agent" });
		console.log(`Found ${agentUsers.length} agent users`);

		// Delete any existing agents
		await Agent.deleteMany({});
		console.log("Cleared existing agents");

		// Create agents
		const now = new Date();
		const shiftEnd = new Date(now.getTime() + 8 * 60 * 60 * 1000); // 8 hour shift

		const agents = [];
		for (const user of agentUsers) {
			const agent = new Agent({
				user: user._id,
				name: user.name,
				email: user.email,
				status: "online",
				currentTicket: null,
				activeTickets: [],
				shift: {
					start: now,
					end: shiftEnd,
					timezone: "UTC",
				},
				maxTickets: 5,
				currentLoad: 0,
				skills: [
					{ name: "Technical Support", level: 4 },
					{ name: "Software", level: 3 },
				],
				department: "Technical",
				teams: ["Support"],
				specializations: ["Networking", "Security"],
			});

			agents.push(agent);
		}

		// Save to database
		await Agent.insertMany(agents);
		console.log(`Created ${agents.length} agent records successfully!`);

		// Display created agents
		agents.forEach((agent) => {
			console.log(
				`- ${agent.name}: status=${agent.status}, department=${agent.department}`
			);
		});

		process.exit(0);
	} catch (error) {
		console.error("Error creating agents:", error);
		process.exit(1);
	}
}
