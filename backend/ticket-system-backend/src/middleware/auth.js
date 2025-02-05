const jwt = require("jsonwebtoken");
const asyncHandler = require("../utils/asyncHandler");
const User = require("../models/User");

module.exports = asyncHandler(async (req, res, next) => {
	let token;

	if (
		req.headers.authorization &&
		req.headers.authorization.startsWith("Bearer")
	) {
		token = req.headers.authorization.split(" ")[1];
	} else if (req.cookies?.token) {
		token = req.cookies.token;
	}

	if (!token) {
		res.status(401);
		throw new Error("Not authorized - No token provided");
	}

	try {
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user = await User.findById(decoded.id).select("-password");

		if (!user) {
			res.status(401);
			throw new Error("User not found");
		}

		// Check if token was issued before password change
		if (
			user.passwordChangedAt &&
			decoded.iat < user.passwordChangedAt.getTime() / 1000
		) {
			res.status(401);
			throw new Error("Password recently changed. Please log in again");
		}

		req.user = user;
		req.userPermissions = await getRolePermissions(user.role);

		next();
	} catch (err) {
		res.status(401);
		if (err.name === "JsonWebTokenError") {
			throw new Error("Invalid token");
		}
		if (err.name === "TokenExpiredError") {
			throw new Error("Token expired");
		}
		throw err;
	}
});

async function getRolePermissions(role) {
	// Define role-based permissions
	const permissionMap = {
		admin: ["all"],
		agent: [
			"read:tickets",
			"update:tickets",
			"read:profile",
			"update:profile",
			"claim:ticket",
			"update:status",
		],
		user: ["create:tickets", "read:tickets", "read:profile", "update:profile"],
	};

	return permissionMap[role] || [];
}
