const logger = require("../utils/logger");

const errorHandler = (err, req, res, next) => {
	// Default error status
	let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
	let message = err.message;

	// Handle Mongoose validation errors
	if (err.name === "ValidationError") {
		statusCode = 400;
		message = Object.values(err.errors)
			.map((error) => error.message)
			.join(", ");
	}

	// Handle Mongoose duplicate key errors
	if (err.code === 11000) {
		statusCode = 409;
		message = `Duplicate field value: ${Object.keys(err.keyValue).join(", ")}`;
	}

	// Handle JWT errors
	if (err.name === "JsonWebTokenError") {
		statusCode = 401;
		message = "Invalid token";
	}

	if (err.name === "TokenExpiredError") {
		statusCode = 401;
		message = "Token expired";
	}

	// Log server errors but not client errors
	if (statusCode >= 500) {
		logger.error(`${err.name}: ${err.message}\n${err.stack}`);
	}

	res.status(statusCode).json({
		success: false,
		message,
		stack: process.env.NODE_ENV === "production" ? null : err.stack,
	});
};

module.exports = errorHandler;
