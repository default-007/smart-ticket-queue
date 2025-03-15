// optimized-seed.js - Seed script for Smart Ticketing System
require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

// Connect to MongoDB
mongoose
	.connect(process.env.MONGODB_URI)
	.then(() => console.log("MongoDB connected for seeding..."))
	.catch((err) => {
		console.error("MongoDB connection error:", err);
		process.exit(1);
	});

const User = require("../src/models/User");
const Agent = require("../src/models/Agent");
const Ticket = require("../src/models/Ticket");
const SLAConfig = require("../src/models/SLAConfig");
const Notification = require("../src/models/Notification");
const Shift = require("../src/models/Shift");

// Helper function to generate random date within range
const randomDate = (start, end) => {
	return new Date(
		start.getTime() + Math.random() * (end.getTime() - start.getTime())
	);
};

// Helper to get random element from array
const getRandomElement = (array) => {
	return array[Math.floor(Math.random() * array.length)];
};

// Helper to get random integer in range
const getRandomInt = (min, max) => {
	return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Helper to verify ObjectId
const isValidObjectId = (id) => {
	return mongoose.Types.ObjectId.isValid(id);
};

// Create seed data
const seedDatabase = async () => {
	try {
		// Clean existing data
		await Promise.all([
			User.deleteMany({}),
			Agent.deleteMany({}),
			Ticket.deleteMany({}),
			Notification.deleteMany({}),
		]);

		console.log("Database cleaned");

		// 1. Create Users
		console.log("Creating users...");

		// Hash password once for reuse
		const hashedPassword = await bcrypt.hash("password123", 10);

		// Create admin
		const adminUser = await User.create({
			name: "Admin User",
			email: "admin@example.com",
			password: hashedPassword,
			role: "admin",
		});

		// Create agents
		const agentUsers = await User.insertMany([
			{
				name: "Sarah Johnson",
				email: "sarah@example.com",
				password: hashedPassword,
				role: "agent",
			},
			{
				name: "Michael Chen",
				email: "michael@example.com",
				password: hashedPassword,
				role: "agent",
			},
			{
				name: "Priya Patel",
				email: "priya@example.com",
				password: hashedPassword,
				role: "agent",
			},
		]);

		// Create regular users
		const regularUsers = await User.insertMany([
			{
				name: "John Doe",
				email: "john@example.com",
				password: hashedPassword,
				role: "user",
			},
			{
				name: "Jane Smith",
				email: "jane@example.com",
				password: hashedPassword,
				role: "user",
			},
		]);

		console.log(
			`Created ${agentUsers.length} agent users and ${regularUsers.length} regular users`
		);

		// 2. Create Agents
		console.log("Creating agent profiles...");

		const skills = [
			"Technical Support",
			"Account Management",
			"Billing",
			"Product Knowledge",
			"Software",
			"Hardware",
			"Networking",
		];

		const departments = ["Technical", "Billing", "General Support"];

		const agents = [];

		for (const user of agentUsers) {
			const now = new Date();
			const shiftStart = new Date(now);
			shiftStart.setHours(9, 0, 0, 0);

			const shiftEnd = new Date(now);
			shiftEnd.setHours(17, 0, 0, 0);

			// Random selection of skills for each agent
			const agentSkills = [];
			const numSkills = getRandomInt(2, 4);
			const availableSkills = [...skills];

			for (let i = 0; i < numSkills; i++) {
				if (availableSkills.length === 0) break;
				const randomIndex = Math.floor(Math.random() * availableSkills.length);
				agentSkills.push(availableSkills.splice(randomIndex, 1)[0]);
			}

			const agent = await Agent.create({
				name: user.name,
				email: user.email,
				status: getRandomElement(["online", "offline", "busy"]),
				user: user._id,
				department: getRandomElement(departments),
				skills: agentSkills,
				maxTickets: getRandomInt(5, 8),
				currentLoad: getRandomInt(0, 5),
				activeTickets: [],
				shift: {
					start: shiftStart,
					end: shiftEnd,
					timezone: "UTC",
				},
			});

			agents.push(agent);
		}

		console.log(`Created ${agents.length} agent profiles`);

		// 3. Create Tickets
		console.log("Creating tickets...");

		const ticketStatuses = [
			"queued",
			"assigned",
			"in-progress",
			"resolved",
			"closed",
		];
		const ticketTitles = [
			"Unable to login to account",
			"Billing discrepancy on monthly statement",
			"Feature request for dashboard",
			"System crashes on file upload",
			"Password reset not working",
			"Error message when submitting form",
			"Request for account upgrade",
			"API integration issue",
			"Data migration assistance",
			"Performance issues with web application",
		];

		const categories = ["technical", "billing", "general", "urgent"];

		const tickets = [];
		const now = new Date();
		const oneMonthAgo = new Date(now);
		oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

		for (let i = 0; i < 20; i++) {
			const creationDate = randomDate(oneMonthAgo, now);
			const dueDate = new Date(creationDate);
			dueDate.setDate(dueDate.getDate() + getRandomInt(1, 7)); // Due 1-7 days after creation

			const priority = getRandomInt(1, 3); // 1 (high) to 3 (low)
			const status = getRandomElement(ticketStatuses);
			const creator = getRandomElement([...regularUsers, ...agentUsers]);
			const assignedAgent =
				status !== "queued" ? getRandomElement(agents) : null;

			// Set up SLA based on priority
			const responseDuration = priority === 1 ? 30 : priority === 2 ? 60 : 120; // minutes
			const resolutionDuration = priority === 1 ? 4 : priority === 2 ? 8 : 24; // hours

			const responseDeadline = new Date(creationDate);
			responseDeadline.setMinutes(
				responseDeadline.getMinutes() + responseDuration
			);

			const resolutionDeadline = new Date(creationDate);
			resolutionDeadline.setHours(
				resolutionDeadline.getHours() + resolutionDuration
			);

			// Determine if SLA was met based on status
			const responseTimeMet = ["resolved", "closed"].includes(status);
			const resolutionTimeMet = ["resolved", "closed"].includes(status);

			// Create SLA object
			const sla = {
				responseTime: {
					deadline: responseDeadline,
					met: responseTimeMet,
				},
				resolutionTime: {
					deadline: resolutionDeadline,
					met: resolutionTimeMet,
				},
			};

			// Create ticket history
			const history = [
				{
					action: "created",
					performedBy: creator._id,
					timestamp: creationDate,
					details: { initialStatus: "queued" },
				},
			];

			try {
				// Include category only if it's used in your model
				const ticketData = {
					title: getRandomElement(ticketTitles),
					description: `Detailed description for ticket #${
						i + 1
					}. This is a sample ticket generated for testing purposes.`,
					status,
					priority,
					dueDate,
					estimatedHours: getRandomInt(1, 6),
					assignedTo: assignedAgent ? assignedAgent._id : null,
					createdBy: creator._id,
					createdAt: creationDate,
					updatedAt: creationDate,
					department: assignedAgent
						? assignedAgent.department
						: getRandomElement(departments),
					sla,
					history,
				};

				// Add category field if your schema uses it
				if (categories.length > 0) {
					ticketData.category = getRandomElement(categories);
				}

				const ticket = await Ticket.create(ticketData);
				tickets.push(ticket);

				// Update agent if assigned
				if (assignedAgent && ["assigned", "in-progress"].includes(status)) {
					assignedAgent.activeTickets.push(ticket._id);
					assignedAgent.currentLoad += ticket.estimatedHours;
					await assignedAgent.save();
				}
			} catch (error) {
				console.error(`Error creating ticket ${i + 1}:`, error.message);
			}
		}

		console.log(`Created ${tickets.length} tickets`);

		// 4. Create Notifications
		console.log("Creating notifications...");

		const notificationTypes = [
			"ticket_assigned",
			"sla_breach",
			"escalation",
			"shift_ending",
			"handover",
			"break_reminder",
		];

		const notifications = [];

		// Create notifications for users (not agents)
		// Based on inspection, recipient must be a valid User ObjectId
		for (const user of [...agentUsers, ...regularUsers]) {
			try {
				if (!isValidObjectId(user._id)) {
					console.log(
						`Skipping notification for user with invalid ID: ${user._id}`
					);
					continue;
				}

				const type = getRandomElement(notificationTypes);
				const ticket = getRandomElement(tickets);

				const message =
					type === "ticket_assigned"
						? `New ticket assigned: ${ticket.title}`
						: type === "sla_breach"
						? `SLA breach alert for ticket #${ticket._id}`
						: type === "escalation"
						? `Ticket ${ticket.title} has been escalated`
						: type === "shift_ending"
						? "Your shift ends in 30 minutes"
						: type === "handover"
						? "Please prepare for ticket handover"
						: "Your scheduled break starts in 15 minutes";

				const notificationData = {
					type,
					recipient: user._id, // Direct User ObjectId reference
					message,
					read: Math.random() > 0.7,
					ticket: ticket._id,
				};

				const notification = await Notification.create(notificationData);
				notifications.push(notification);
			} catch (error) {
				console.error(
					`Error creating notification for user ${user.name}:`,
					error.message
				);
				// Continue with the next user
			}
		}

		// Create unread notification for admin
		try {
			if (isValidObjectId(adminUser._id)) {
				const adminNotification = await Notification.create({
					type: "sla_breach",
					recipient: adminUser._id,
					message: "Multiple SLA breaches detected in Technical department",
					read: false,
				});

				notifications.push(adminNotification);
			}
		} catch (error) {
			console.error("Error creating admin notification:", error.message);
		}

		console.log(`Created ${notifications.length} notifications`);
		console.log("Database seeded successfully");

		// Return some login credentials for testing
		return {
			admin: { email: "admin@example.com", password: "password123" },
			agent: { email: "sarah@example.com", password: "password123" },
			user: { email: "john@example.com", password: "password123" },
		};
	} catch (error) {
		console.error("Error seeding database:", error);
		throw error;
	}
};

// Run the seed function
seedDatabase()
	.then((credentials) => {
		console.log("Use these credentials to test the system:");
		console.log("Admin:", credentials.admin);
		console.log("Agent:", credentials.agent);
		console.log("User:", credentials.user);

		// Disconnect from database
		return mongoose.disconnect();
	})
	.then(() => {
		console.log("Database connection closed");
		process.exit(0);
	})
	.catch((error) => {
		console.error("Seeding failed:", error);
		mongoose.disconnect();
		process.exit(1);
	});
