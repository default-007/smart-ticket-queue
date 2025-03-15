// src/middleware/checkPermission.js
const { hasPermission } = require("../config/permissions");

const checkPermission = (permission) => {
	return (req, res, next) => {
		const userRole = req.user?.role;

		// If user is admin, always allow
		if (userRole === "admin" || hasPermission(userRole, permission)) {
			return next();
		}

		return res.status(403).json({
			success: false,
			message: "You do not have permission to perform this action",
		});
	};
};

// Additional helper middleware specifically for admin
const adminOnly = (req, res, next) => {
	if (req.user?.role !== "admin") {
		return res.status(403).json({
			success: false,
			message: "Only administrators can perform this action",
		});
	}
	next();
};

module.exports = checkPermission;
