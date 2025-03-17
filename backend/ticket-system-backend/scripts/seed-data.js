// seed.js - Script to populate the database with test data

require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

// Import Models
const User = require("../src/models/User");
const Agent = require("../src/models/Agent");
const Ticket = require("../src/models/Ticket");
const SLAConfig = require("../src/models/SLAConfig");
const Notification = require("../src/models/Notification");
const Shift = require("../src/models/Shift");

// Connect to MongoDB
mongoose
	.connect(process.env.MONGODB_URI, {
		useNewUrlParser: true,
		useUnifiedTopology: true,
	})
	.then(() => console.log("MongoDB Connected"))
	.catch((err) => {
		console.error("MongoDB Connection Error:", err);
		process.exit(1);
	});

// Helper function to hash passwords
const hashPassword = async (password) => {
	const salt = await bcrypt.genSalt(10);
	return await bcrypt.hash(password, salt);
};

// Clear existing data
const clearDatabase = async () => {
	try {
		console.log("Clearing existing data...");
		await User.deleteMany({});
		await Agent.deleteMany({});
		await Ticket.deleteMany({});
		await Notification.deleteMany({});
		await Shift.deleteMany({});
		console.log("Database cleared successfully");
	} catch (error) {
		console.error("Error clearing database:", error);
		process.exit(1);
	}
};

// Create Admin, Agents and Users
const createUsers = async () => {
	try {
		console.log("Creating users...");

		// Create Admin User
		const adminPassword = await hashPassword("admin123");
		const admin = await User.create({
			name: "Admin User",
			email: "admin@example.com",
			password: adminPassword,
			role: "admin",
		});
		console.log("Admin created:", admin.email);

		// Create 6 Agents with corresponding Agent profiles
		const agents = [];
		const agentRecords = [];

		for (let i = 1; i <= 6; i++) {
			const agentPassword = await hashPassword(`agent${i}`);
			const agent = await User.create({
				name: `Agent ${i}`,
				email: `agent${i}@example.com`,
				password: agentPassword,
				role: "agent",
			});

			const department = i <= 2 ? "Technical" : i <= 4 ? "Billing" : "General";

			// Assign different skills based on agent number
			const skills = [];
			if (i <= 3) skills.push("Hardware", "Software");
			if (i >= 2 && i <= 5) skills.push("Network", "Security");
			if (i >= 4) skills.push("Billing", "Accounts");
			if (i % 2 === 0) skills.push("Documentation");

			// Create Agent profile
			const agentRecord = await Agent.create({
				name: agent.name,
				email: agent.email,
				status: i % 3 === 0 ? "busy" : i % 3 === 1 ? "online" : "offline",
				user: agent._id,
				department,
				skills,
				maxTickets: 5 + (i % 3),
				currentLoad: i % 4,
				activeTickets: [],
				shift: {
					start: new Date(),
					end: new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
					timezone: "UTC",
				},
			});

			agents.push(agent);
			agentRecords.push(agentRecord);
			console.log(`Agent created: ${agent.email}`);
		}

		// Create 5 Regular Users
		const users = [];
		for (let i = 1; i <= 5; i++) {
			const userPassword = await hashPassword(`user${i}`);
			const user = await User.create({
				name: `User ${i}`,
				email: `user${i}@example.com`,
				password: userPassword,
				role: "user",
			});
			users.push(user);
			console.log(`User created: ${user.email}`);
		}

		return { admin, agents, agentRecords, users };
	} catch (error) {
		console.error("Error creating users:", error);
		process.exit(1);
	}
};

// Create tickets with various statuses and priorities
const createTickets = async (users, agentRecords) => {
	try {
		console.log("Creating tickets...");

		const tickets = [];
		const ticketStatuses = [
			"queued",
			"assigned",
			"in-progress",
			"resolved",
			"closed",
			"escalated",
		];
		const ticketCategories = ["technical", "billing", "general", "urgent"];
		const ticketTitles = [
			"Cannot login to the system",
			"Billing discrepancy on invoice #123456",
			"Request for software installation",
			"Network connectivity issues",
			"Password reset required",
			"Printer not working",
			"Monitor display issues",
			"Email not sending",
			"Account lockout",
			"VPN connection problems",
			"New laptop request",
			"Software license expired",
			"Data migration assistance",
			"File access permission issue",
			"Can't access shared drive",
			"System running slow",
			"Application crash on startup",
			"Website error 404",
			"Excel formula help needed",
			"Mobile app sync failure",
		];

		// Create 20 tickets with different statuses, priorities, and assignments
		for (let i = 0; i < 20; i++) {
			const createdBy = users[i % users.length]._id;
			const title = ticketTitles[i];
			const status = ticketStatuses[i % ticketStatuses.length];
			const priority = (i % 3) + 1; // 1, 2, or 3
			const category = ticketCategories[i % ticketCategories.length];

			// Calculate due date based on priority (higher priority = shorter deadline)
			const dueDate = new Date();
			dueDate.setDate(dueDate.getDate() + (4 - priority) * 2); // Priority 1: 6 days, 2: 4 days, 3: 2 days

			// Decide if this ticket should be assigned to an agent
			let assignedTo = null;
			if (status !== "queued") {
				assignedTo = agentRecords[i % agentRecords.length]._id;
			}

			// Estimate time needed based on category and priority
			const estimatedHours =
				Math.max(1, 4 - priority) + (Math.floor(i / 4) % 3);

			// SLA configuration
			const sla = {
				responseTime: {
					deadline: new Date(
						new Date().getTime() + (4 - priority) * 60 * 60 * 1000
					),
					met: status !== "queued",
				},
				resolutionTime: {
					deadline: new Date(
						new Date().getTime() + (4 - priority) * 24 * 60 * 60 * 1000
					),
					met: status === "resolved" || status === "closed",
				},
			};

			// Escalate some tickets for testing
			const escalationLevel =
				status === "escalated" ? Math.floor(i / 15) + 1 : 0;

			// Create ticket history
			const history = [
				{
					action: "created",
					performedBy: createdBy,
					timestamp: new Date(new Date().getTime() - 1000000),
					details: { initialStatus: "queued" },
				},
			];

			// Add assignment history if assigned
			if (assignedTo) {
				history.push({
					action: "assigned",
					performedBy: assignedTo,
					timestamp: new Date(new Date().getTime() - 800000),
					details: { agentId: assignedTo },
				});
			}

			// Add status update history for in-progress tickets
			if (status === "in-progress") {
				history.push({
					action: "status_updated",
					performedBy: assignedTo,
					timestamp: new Date(new Date().getTime() - 600000),
					details: { oldStatus: "assigned", newStatus: "in-progress" },
				});
			}

			// Add resolution history for resolved tickets
			if (status === "resolved" || status === "closed") {
				history.push({
					action: status === "resolved" ? "resolved" : "closed",
					performedBy: assignedTo,
					timestamp: new Date(new Date().getTime() - 300000),
					details: { resolution: "Issue has been fixed" },
				});
			}

			// Add escalation history for escalated tickets
			if (status === "escalated") {
				history.push({
					action: "escalated",
					performedBy: assignedTo || createdBy,
					timestamp: new Date(new Date().getTime() - 200000),
					details: {
						reason: "SLA breach",
						previousLevel: escalationLevel - 1,
						newLevel: escalationLevel,
					},
				});
			}

			const ticket = await Ticket.create({
				title,
				description: `This is a test ticket description for ${title}. This is generated for testing purposes.`,
				status,
				priority,
				category,
				dueDate,
				estimatedHours,
				assignedTo,
				createdBy,
				department:
					category === "technical"
						? "Technical"
						: category === "billing"
						? "Billing"
						: "Support",
				requiredSkills:
					category === "technical"
						? ["Hardware", "Software"]
						: category === "billing"
						? ["Billing", "Accounts"]
						: ["Documentation"],
				sla,
				escalationLevel,
				history,
				firstResponseTime:
					status !== "queued"
						? new Date(new Date().getTime() - 750000)
						: undefined,
				resolvedAt:
					status === "resolved" || status === "closed" ? new Date() : undefined,
				resolutionTime:
					status === "resolved" || status === "closed"
						? Math.floor(Math.random() * 500) + 100
						: undefined, // Random resolution time in minutes
			});

			tickets.push(ticket);

			// Update agent's activeTickets if assigned
			if (assignedTo) {
				const agentToUpdate = await Agent.findById(assignedTo);
				if (agentToUpdate) {
					agentToUpdate.activeTickets = [
						...agentToUpdate.activeTickets,
						ticket._id,
					];
					agentToUpdate.currentLoad += estimatedHours;
					await agentToUpdate.save();
				}
			}

			console.log(`Ticket created: ${ticket.title}`);
		}

		return tickets;
	} catch (error) {
		console.error("Error creating tickets:", error);
		process.exit(1);
	}
};

// Create SLA configurations
const createSLAConfigs = async () => {
	try {
		console.log("Creating SLA configurations...");

		// Clear existing SLA configs
		await SLAConfig.deleteMany({});

		// Define SLA configurations for different priority/category combinations
		const slaConfigs = [
			// High Priority (1)
			{
				priority: 1,
				category: "urgent",
				responseTime: 30, // 30 minutes
				resolutionTime: 120, // 2 hours
				escalationRules: [
					{
						level: 1,
						threshold: 30,
						notifyRoles: ["admin", "supervisor"],
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
				responseTime: 60, // 1 hour
				resolutionTime: 240, // 4 hours
				escalationRules: [
					{
						level: 1,
						threshold: 45,
						notifyRoles: ["admin", "supervisor"],
					},
				],
			},
			{
				priority: 1,
				category: "billing",
				responseTime: 60, // 1 hour
				resolutionTime: 240, // 4 hours
				escalationRules: [
					{
						level: 1,
						threshold: 45,
						notifyRoles: ["admin", "supervisor"],
					},
				],
			},
			{
				priority: 1,
				category: "general",
				responseTime: 60, // 1 hour
				resolutionTime: 240, // 4 hours
				escalationRules: [
					{
						level: 1,
						threshold: 45,
						notifyRoles: ["admin", "supervisor"],
					},
				],
			},

			// Medium Priority (2)
			{
				priority: 2,
				category: "urgent",
				responseTime: 120, // 2 hours
				resolutionTime: 480, // 8 hours
				escalationRules: [
					{
						level: 1,
						threshold: 60,
						notifyRoles: ["supervisor"],
					},
				],
			},
			{
				priority: 2,
				category: "technical",
				responseTime: 240, // 4 hours
				resolutionTime: 720, // 12 hours
				escalationRules: [
					{
						level: 1,
						threshold: 120,
						notifyRoles: ["supervisor"],
					},
				],
			},
			{
				priority: 2,
				category: "billing",
				responseTime: 240, // 4 hours
				resolutionTime: 720, // 12 hours
				escalationRules: [
					{
						level: 1,
						threshold: 120,
						notifyRoles: ["supervisor"],
					},
				],
			},
			{
				priority: 2,
				category: "general",
				responseTime: 240, // 4 hours
				resolutionTime: 720, // 12 hours
				escalationRules: [
					{
						level: 1,
						threshold: 120,
						notifyRoles: ["supervisor"],
					},
				],
			},

			// Low Priority (3)
			{
				priority: 3,
				category: "urgent",
				responseTime: 480, // 8 hours
				resolutionTime: 1440, // 24 hours
				escalationRules: [],
			},
			{
				priority: 3,
				category: "technical",
				responseTime: 480, // 8 hours
				resolutionTime: 1440, // 24 hours
				escalationRules: [],
			},
			{
				priority: 3,
				category: "billing",
				responseTime: 480, // 8 hours
				resolutionTime: 1440, // 24 hours
				escalationRules: [],
			},
			{
				priority: 3,
				category: "general",
				responseTime: 480, // 8 hours
				resolutionTime: 1440, // 24 hours
				escalationRules: [],
			},
		];

		for (const config of slaConfigs) {
			await SLAConfig.create(config);
		}

		console.log(`Created ${slaConfigs.length} SLA configurations`);
	} catch (error) {
		console.error("Error creating SLA configurations:", error);
		process.exit(1);
	}
};

// Create notifications
const createNotifications = async (users, agents, tickets) => {
	try {
		console.log("Creating notifications...");

		const notifications = [];
		const notificationTypes = [
			"ticket_assigned",
			"sla_breach",
			"escalation",
			"shift_ending",
			"handover",
			"break_reminder",
		];

		// Create 15 notifications
		for (let i = 0; i < 15; i++) {
			const type = notificationTypes[i % notificationTypes.length];
			const recipient =
				i % 3 === 0
					? users[i % users.length]._id
					: agents[i % agents.length]._id;

			let message = "";
			let ticket = i < tickets.length ? tickets[i]._id : null;
			let metadata = {};

			switch (type) {
				case "ticket_assigned":
					message = `Ticket #${i + 1} has been assigned to you`;
					metadata = { priority: (i % 3) + 1 };
					break;
				case "sla_breach":
					message = `SLA breach alert for ticket #${i + 1}`;
					metadata = { breachType: "response_time", priority: (i % 3) + 1 };
					break;
				case "escalation":
					message = `Ticket #${i + 1} has been escalated`;
					metadata = { escalationLevel: (i % 2) + 1 };
					break;
				case "shift_ending":
					message = `Your shift is ending in 30 minutes`;
					ticket = null;
					metadata = { activeTickets: 3 };
					break;
				case "handover":
					message = `Ticket #${i + 1} has been handed over to you`;
					metadata = { fromAgent: agents[(i + 1) % agents.length]._id };
					break;
				case "break_reminder":
					message = `Your scheduled break starts in 15 minutes`;
					ticket = null;
					metadata = { breakType: "lunch", duration: 60 };
					break;
			}

			const notification = await Notification.create({
				type,
				recipient,
				message,
				read: i % 3 === 0, // Some read, some unread
				ticket,
				metadata,
			});

			notifications.push(notification);
		}

		console.log(`Created ${notifications.length} notifications`);
	} catch (error) {
		console.error("Error creating notifications:", error);
		process.exit(1);
	}
};

// Create agent shifts
const createShifts = async (agentRecords) => {
	try {
		console.log("Creating agent shifts...");

		const shifts = [];

		for (let i = 0; i < agentRecords.length; i++) {
			const agent = agentRecords[i];

			// Current day shift
			const today = new Date();
			const startTime = new Date(today);
			startTime.setHours(9, 0, 0, 0); // 9:00 AM

			const endTime = new Date(today);
			endTime.setHours(17, 0, 0, 0); // 5:00 PM

			const shift = await Shift.create({
				agent: agent._id,
				start: startTime,
				end: endTime,
				status: i % 2 === 0 ? "in-progress" : "scheduled",
				breaks: [
					{
						start: new Date(new Date(startTime).setHours(12, 0, 0, 0)), // 12:00 PM
						end: new Date(new Date(startTime).setHours(13, 0, 0, 0)), // 1:00 PM
						type: "lunch",
						status: i % 2 === 0 ? "scheduled" : "completed",
					},
					{
						start: new Date(new Date(startTime).setHours(15, 0, 0, 0)), // 3:00 PM
						end: new Date(new Date(startTime).setHours(15, 15, 0, 0)), // 3:15 PM
						type: "short-break",
						status: "scheduled",
					},
				],
				timezone: "UTC",
			});

			shifts.push(shift);

			// Tomorrow's shift
			const tomorrow = new Date(today);
			tomorrow.setDate(tomorrow.getDate() + 1);

			const tomorrowStartTime = new Date(tomorrow);
			tomorrowStartTime.setHours(9, 0, 0, 0); // 9:00 AM

			const tomorrowEndTime = new Date(tomorrow);
			tomorrowEndTime.setHours(17, 0, 0, 0); // 5:00 PM

			const tomorrowShift = await Shift.create({
				agent: agent._id,
				start: tomorrowStartTime,
				end: tomorrowEndTime,
				status: "scheduled",
				breaks: [
					{
						start: new Date(new Date(tomorrowStartTime).setHours(12, 0, 0, 0)), // 12:00 PM
						end: new Date(new Date(tomorrowStartTime).setHours(13, 0, 0, 0)), // 1:00 PM
						type: "lunch",
						status: "scheduled",
					},
				],
				timezone: "UTC",
			});

			shifts.push(tomorrowShift);
		}

		console.log(`Created ${shifts.length} shifts`);
	} catch (error) {
		console.error("Error creating shifts:", error);
		process.exit(1);
	}
};

// Run the seed process
const seedDatabase = async () => {
	try {
		await clearDatabase();
		const { admin, agents, agentRecords, users } = await createUsers();
		const tickets = await createTickets(users, agentRecords);
		await createSLAConfigs();
		await createNotifications(users, agents, tickets);
		await createShifts(agentRecords);

		console.log("Database seeded successfully!");
		console.log("\nTest User Credentials:");
		console.log("----------------------");
		console.log("Admin: admin@example.com / admin123");
		console.log(
			"Agents: agent1@example.com through agent6@example.com / password matches email prefix"
		);
		console.log(
			"Users: user1@example.com through user5@example.com / password matches email prefix"
		);

		mongoose.disconnect();
		console.log("MongoDB disconnected");
	} catch (error) {
		console.error("Error seeding database:", error);
		process.exit(1);
	}
};

// Execute the seed process
seedDatabase();
