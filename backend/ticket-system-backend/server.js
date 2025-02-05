// server.js
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
require("dotenv").config();

const ticketRoutes = require("./src/routes/ticketRoutes");
const agentRoutes = require("./src/routes/agentRoutes");
const authRoutes = require("./src/routes/authRoutes");
const errorHandler = require("./src/middleware/errorHandler");
const WebSocketService = require("./src/services/websocketService");
const SchedulerService = require("./src/services/schedulerService");

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize WebSocket Service
const wsService = new WebSocketService(server);
global.io = wsService.io;

// Initialize Scheduler Service
let scheduler = null;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

// Rate limiting
const limiter = rateLimit({
	windowMs: 15 * 60 * 1000, // 15 minutes
	max: 100, // limit each IP to 100 requests per windowMs
});
app.use("/api", limiter);

// Routes
app.use("/api/auth", require("./src/routes/authRoutes"));
app.use("/api/tickets", require("./src/routes/ticketRoutes"));
app.use("/api/agents", require("./src/routes/agentRoutes"));
app.use("/api/notifications", require("./src/routes/notificationRoutes"));
app.use("/api/sla", require("./src/routes/slaRoutes"));

// Base route for testing
app.get("/", (req, res) => {
	res.json({ message: "API is running" });
});

// Error handling
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;

// Database connection and server start
mongoose
	.connect(process.env.MONGODB_URI, {
		useNewUrlParser: true,
		useUnifiedTopology: true,
	})
	.then(() => {
		console.log("Connected to MongoDB");
		// Initialize scheduler after database connection
		scheduler = new SchedulerService();
		server.listen(PORT, () => {
			console.log(`Server is running on port ${PORT}`);
		});
	})
	.catch((err) => {
		console.error("MongoDB connection error:", err);
		process.exit(1);
	});

// Handle unhandled promise rejections
process.on("unhandledRejection", (err) => {
	console.error("Unhandled Promise Rejection:", err);
	// Close server & exit process
	server.close(() => process.exit(1));
});

// Graceful shutdown
process.on("SIGTERM", async () => {
	console.log("SIGTERM received. Shutting down gracefully...");
	if (scheduler) {
		// Stop all scheduled tasks
		scheduler.stopAll && scheduler.stopAll();
	}
	server.close(() => {
		console.log("Process terminated");
		process.exit(0);
	});
});

module.exports = app;
