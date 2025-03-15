const authorize = (...roleArrays) => {
	return (req, res, next) => {
		// Flatten the roles array
		const roles = roleArrays.flat();

		// If no roles are specified, allow all roles
		if (roles.length === 0) {
			return next();
		}

		// Always allow admin
		if (req.user.role === "admin") {
			return next();
		}

		// Check if user's role is in the allowed roles
		if (!roles.includes(req.user.role)) {
			res.status(403);
			throw new Error(
				`User role ${req.user.role} is not authorized to access this route`
			);
		}

		next();
	};
};

module.exports = authorize;
