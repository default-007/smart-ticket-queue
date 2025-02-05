const asyncHandler = require("../utils/asyncHandler");
const User = require("../models/User");
const jwt = require("jsonwebtoken");

exports.register = asyncHandler(async (req, res) => {
	const { name, email, password, role } = req.body;

	// Only allow admin to create other admins
	if (role === "admin" && (!req.user || req.user.role !== "admin")) {
		res.status(403);
		throw new Error("Not authorized to create admin accounts");
	}

	const user = await User.create({
		name,
		email,
		password,
		role: role || "user",
	});

	// Generate token
	const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
		expiresIn: "30d",
	});

	// Send response
	res.status(201).json({
		success: true,
		token,
		data: {
			id: user._id,
			name: user.name,
			email: user.email,
			role: user.role,
		},
	});
});

exports.login = asyncHandler(async (req, res) => {
	const { email, password } = req.body;

	if (!email || !password) {
		res.status(400);
		throw new Error("Please provide email and password");
	}

	// Check if user exists
	const user = await User.findOne({ email }).select("+password");

	if (!user) {
		res.status(401);
		throw new Error("Invalid credentials");
	}

	// Check password
	const isMatch = await user.matchPassword(password);

	if (!isMatch) {
		res.status(401);
		throw new Error("Invalid credentials");
	}

	// Generate token
	const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
		expiresIn: "30d",
	});

	// Send response
	res.json({
		success: true,
		token,
		data: {
			id: user._id,
			name: user.name,
			email: user.email,
			role: user.role,
		},
	});
});

exports.updateProfile = asyncHandler(async (req, res) => {
	const user = await User.findById(req.user.id);

	if (!user) {
		res.status(404);
		throw new Error("User not found");
	}

	// Check if email is being changed and is already in use
	if (req.body.email && req.body.email !== user.email) {
		const existingUser = await User.findOne({ email: req.body.email });
		if (existingUser) {
			res.status(400);
			throw new Error("Email already in use");
		}
	}

	user.name = req.body.name || user.name;
	user.email = req.body.email || user.email;

	const updatedUser = await user.save();

	res.json({
		success: true,
		data: {
			id: updatedUser._id,
			name: updatedUser.name,
			email: updatedUser.email,
			role: updatedUser.role,
		},
	});
});

exports.changePassword = asyncHandler(async (req, res) => {
	const { currentPassword, newPassword } = req.body;

	const user = await User.findById(req.user.id).select("+password");

	if (!user) {
		res.status(404);
		throw new Error("User not found");
	}

	// Check current password
	const isMatch = await user.matchPassword(currentPassword);
	if (!isMatch) {
		res.status(401);
		throw new Error("Current password is incorrect");
	}

	user.password = newPassword;
	await user.save();

	res.json({
		success: true,
		message: "Password updated successfully",
	});
});

// Test endpoint
exports.test = asyncHandler(async (req, res) => {
	res.json({
		success: true,
		message: "API is working!",
	});
});

exports.getMe = asyncHandler(async (req, res) => {
	const user = await User.findById(req.user.id);

	res.json({
		success: true,
		data: {
			id: user._id,
			name: user.name,
			email: user.email,
			role: user.role,
		},
	});
});

exports.logout = asyncHandler(async (req, res) => {
	res.json({
		success: true,
		message: "Logged out successfully",
	});
});
