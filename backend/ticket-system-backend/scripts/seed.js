const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

// Import models
const User = require("../src/models/User");
const Agent = require("../src/models/Agent");
const Ticket = require("../src/models/Ticket");

// MongoDB connection string
const MONGODB_URI =
	process.env.MONGODB_URI || "mongodb://localhost:27017/ticketing_system";

// Sample data generation functions
const generateUsers = async () => {
	const salt = await bcrypt.genSalt(10);
	return [
		{
			name: "Admin User",
			email: "admin@example.com",
			password: await bcrypt.hash("AdminPass123!", salt),
			role: "admin",
		},
		{
			name: "John Smith",
			email: "john.smith@example.com",
			password: await bcrypt.hash("AgentPass123!", salt),
			role: "agent",
		},
		{
			name: "Emily Davis",
			email: "emily.davis@example.com",
			password: await bcrypt.hash("AgentPass456!", salt),
			role: "agent",
		},
		{
			name: "Regular User",
			email: "user@example.com",
			password: await bcrypt.hash("UserPass123!", salt),
			role: "user",
		},
	];
};

const generateAgents = (users) => {
	const now = new Date();
	const todayMorning = new Date(
		now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		9,
		0,
		0
	);
	const todayEvening = new Date(
		now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		17,
		0,
		0
	);

	return [
		{
			name: "John Smith",
			email: "john.smith@example.com",
			user: users.find((u) => u.email === "john.smith@example.com")._id,
			status: "online",
			currentTicket: null,
			shift: {
				start: todayMorning,
				end: todayEvening,
				timezone: "UTC",
			},
			maxTickets: 5,
			currentLoad: 0,
			skills: ["frontend", "customer support"],
			department: "IT Support",
		},
		{
			name: "Emily Davis",
			email: "emily.davis@example.com",
			user: users.find((u) => u.email === "emily.davis@example.com")._id,
			status: "online",
			currentTicket: null,
			shift: {
				start: todayMorning,
				end: todayEvening,
				timezone: "UTC",
			},
			maxTickets: 5,
			currentLoad: 0,
			skills: ["backend", "network"],
			department: "Infrastructure",
		},
	];
};

const generateTickets = (users, agents) => {
	const now = new Date();
	const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
	const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

	return [
		{
			title: "Website Performance Issue",
			description:
				"Experiencing slow loading times on the company website. Need urgent investigation.",
			status: "queued",
			priority: 1,
			dueDate: nextWeek,
			estimatedHours: 4,
			assignedTo: null,
			createdBy: users.find((u) => u.email === "user@example.com")._id,
		},
		{
			title: "Email Server Configuration",
			description:
				"Need to reconfigure email server settings for improved deliverability.",
			status: "assigned",
			priority: 2,
			dueDate: tomorrow,
			estimatedHours: 3,
			assignedTo: agents.find((a) => a.email === "john.smith@example.com")._id,
			createdBy: users.find((u) => u.email === "user@example.com")._id,
		},
		{
			title: "Network Switch Replacement",
			description:
				"Replace aging network switch in the server room. Requires careful planning.",
			status: "in-progress",
			priority: 1,
			dueDate: nextWeek,
			estimatedHours: 6,
			assignedTo: agents.find((a) => a.email === "emily.davis@example.com")._id,
			createdBy: users.find((u) => u.role === "admin")._id,
		},
		{
			title: "Security Audit Request",
			description:
				"Conduct a comprehensive security audit of our internal systems.",
			status: "queued",
			priority: 1,
			dueDate: nextWeek,
			estimatedHours: 8,
			assignedTo: null,
			createdBy: users.find((u) => u.role === "admin")._id,
		},
	];
};

// Main seeding function
const seedDatabase = async () => {
	try {
		// Connect to MongoDB
		await mongoose.connect(MONGODB_URI, {
			useNewUrlParser: true,
			useUnifiedTopology: true,
		});
		console.log("Connected to MongoDB");

		// Clear existing data
		await User.deleteMany({});
		await Agent.deleteMany({});
		await Ticket.deleteMany({});

		// Generate and save users
		const users = await User.create(await generateUsers());
		console.log(`${users.length} users created`);

		// Generate and save agents
		const agents = await Agent.create(generateAgents(users));
		console.log(`${agents.length} agents created`);

		// Generate and save tickets
		const tickets = await Ticket.create(generateTickets(users, agents));
		console.log(`${tickets.length} tickets created`);

		console.log("Database seeded successfully");

		// Close the connection
		await mongoose.connection.close();
	} catch (error) {
		console.error("Seeding error:", error);
		process.exit(1);
	}
};

// Run the seeding script
seedDatabase();
