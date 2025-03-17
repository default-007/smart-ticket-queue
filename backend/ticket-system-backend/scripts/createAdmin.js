require("dotenv").config();
const mongoose = require("mongoose");
const User = require("../src/models/User");

const createAdmin = async () => {
	try {
		await mongoose.connect(process.env.MONGODB_URI);
		console.log("Connected to MongoDB");

		const adminData = {
			name: "Admin User",
			email: "default@example.com", // Change this to your desired admin email
			password: "admin123", // Change this to your desired password
			role: "admin",
		};

		// Check if admin already exists
		const existingAdmin = await User.findOne({ email: adminData.email });
		if (existingAdmin) {
			console.log("Admin user already exists");
			process.exit(0);
		}

		// Create admin user
		const admin = await User.create(adminData);
		console.log("Admin user created successfully:", admin);
		process.exit(0);
	} catch (error) {
		console.error("Error creating admin user:", error);
		process.exit(1);
	}
};

createAdmin();
