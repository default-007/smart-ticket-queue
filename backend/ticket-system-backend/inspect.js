const bcrypt = require("bcryptjs");
const mongoose = require("mongoose");
require("dotenv").config();

async function resetPassword() {
	try {
		await mongoose.connect(process.env.MONGODB_URI);

		const User = mongoose.model(
			"User",
			new mongoose.Schema({
				email: String,
				password: String,
			})
		);

		const salt = await bcrypt.genSalt(10);
		const hashedPassword = await bcrypt.hash("password123", salt);

		await User.updateOne(
			{ email: "admin@example.com" },
			{ $set: { password: hashedPassword } }
		);

		console.log("Password reset successful");
	} catch (error) {
		console.error("Error:", error);
	} finally {
		await mongoose.disconnect();
	}
}

resetPassword();
