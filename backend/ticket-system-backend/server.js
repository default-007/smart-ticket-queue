// server.js
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
require("dotenv").config();

const ticketRoutes = require("./src/routes/ticketRoutes");
const agentRoutes = require("./src/routes/agentRoutes");
const authRoutes = require("./src/routes/authRoutes");
const errorHandler = require("./src/middleware/errorHandler");

const app = express();

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

// Base route for testing
app.get("/", (req, res) => {
	res.json({ message: "API is running" });
});

// Error handling middleware
app.use((err, req, res, next) => {
	console.error(err.stack);
	res.status(500).json({
		success: false,
		message: err.message || "Internal Server Error",
		error: process.env.NODE_ENV === "development" ? err : {},
	});
});

// Error handling
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;

// Database connection
mongoose
	.connect(process.env.MONGODB_URI)
	.then(() => {
		console.log("Connected to MongoDB");
		app.listen(PORT, () => {
			console.log(`Server is running on port ${PORT}`);
		});
	})
	.catch((err) => {
		console.error("MongoDB connection error:", err);
	});
