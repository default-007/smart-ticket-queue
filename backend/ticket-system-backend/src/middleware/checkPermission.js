// src/middleware/checkPermission.js
const { hasPermission } = require("../config/permissions");

const checkPermission = (permission) => {
	return (req, res, next) => {
		const userRole = req.user?.role;

		if (!hasPermission(userRole, permission)) {
			return res.status(403).json({
				success: false,
				message: "You do not have permission to perform this action",
			});
		}

		next();
	};
};

module.exports = checkPermission;
