// src/utils/logger.js
const winston = require("winston");
const path = require("path");

// Define log levels
const levels = {
	error: 0,
	warn: 1,
	info: 2,
	http: 3,
	debug: 4,
};

// Define log colors
const colors = {
	error: "red",
	warn: "yellow",
	info: "green",
	http: "magenta",
	debug: "white",
};

// Add colors to winston
winston.addColors(colors);

// Define log format
const format = winston.format.combine(
	winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss:ms" }),
	winston.format.colorize({ all: true }),
	winston.format.printf(
		(info) => `${info.timestamp} ${info.level}: ${info.message}`
	)
);

// Define which transports the logger must use
const transports = [
	// Console transport for all logs
	new winston.transports.Console(),

	// File transport for errors
	new winston.transports.File({
		filename: path.join("logs", "error.log"),
		level: "error",
	}),

	// File transport for all logs
	new winston.transports.File({
		filename: path.join("logs", "all.log"),
	}),
];

// Create the logger
const logger = winston.createLogger({
	level: process.env.NODE_ENV === "development" ? "debug" : "info",
	levels,
	format,
	transports,
});

module.exports = logger;
