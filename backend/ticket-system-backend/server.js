// server.js
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
require("dotenv").config();

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
app.use(
	helmet({
		crossOriginResourcePolicy: { policy: "cross-origin" },
	})
);
app.use(
	cors({
		origin: "*", // Allow all origins for testing
		methods: ["GET", "POST", "PUT", "DELETE"],
		allowedHeaders: ["Content-Type", "Authorization"],
		credentials: true,
	})
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

app.use((err, req, res, next) => {
	if (err instanceof ReferenceError) {
		console.error("Reference Error:", err);
		return res.status(500).json({
			success: false,
			message: "Server configuration error. Please contact an administrator.",
			error: process.env.NODE_ENV === "development" ? err.message : undefined,
		});
	}
	next(err);
});

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
app.use("/api/workload", require("./src/routes/workloadRoutes"));
app.use("/api/shifts", require("./src/routes/shiftRoutes"));

// Base route for testing
app.get("/", (req, res) => {
	console.log("Base route hit");
	res.json({ message: "API is running" });
});

// Test route before auth routes
app.get("/api/test", (req, res) => {
	console.log("Test route hit");
	res.json({ message: "Test successful" });
});

app.post("/api/auth/register", (req, res, next) => {
	console.log("Received registration request:", req.body);
	next();
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
		server.listen(PORT, "0.0.0.0", () => {
			console.log(`Server is running on port ${PORT}`);
		});
	})
	.catch((err) => {
		console.error("MongoDB connection error:", err);
		process.exit(1);
	});

// error event listener to the server
server.on("error", (error) => {
	console.error("Server error:", error);
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
