// src/config/database.js
const mongoose = require("mongoose");

class Database {
	constructor() {
		this.isConnected = false;
	}

	async connect() {
		if (this.isConnected) {
			console.log("Using existing database connection");
			return;
		}

		try {
			const conn = await mongoose.connect(process.env.MONGODB_URI, {
				useNewUrlParser: true,
				useUnifiedTopology: true,
			});

			this.isConnected = true;
			console.log(`MongoDB Connected: ${conn.connection.host}`);
		} catch (error) {
			console.error(`Error: ${error.message}`);
			process.exit(1);
		}
	}

	async disconnect() {
		if (!this.isConnected) {
			return;
		}

		try {
			await mongoose.disconnect();
			this.isConnected = false;
			console.log("Database disconnected");
		} catch (error) {
			console.error(`Error disconnecting from database: ${error.message}`);
			process.exit(1);
		}
	}
}

// Create a singleton instance
const database = new Database();

module.exports = database;
