// src/config/permissions.js
const permissions = {
	admin: {
		tickets: ["create", "read", "update", "delete", "process-queue"],
		agents: ["create", "read", "update", "delete"],
		sla: ["read", "update"],
		system: ["manage"],
		reports: ["view", "generate"],
		all: true,
	},
	agent: {
		tickets: ["read", "update", "claim"],
		profile: ["read", "update"],
		notifications: ["read", "update"],
		restricted: ["view-assigned"],
	},
	user: {
		tickets: ["create", "read-own", "update-own"],
		profile: ["read", "update"],
		notifications: ["read"],
	},
};

const hasPermission = (role, permission) => {
	if (!role || !permission) return false;
	if (permissions[role].all) return true;

	const [resource, action] = permission.split(":");
	return permissions[role][resource]?.includes(action);
};

module.exports = {
	permissions,
	hasPermission,
	checkPermission: (permission) => {
		return (req, res, next) => {
			const userRole = req.user?.role;

			if (!hasPermission(userRole, permission)) {
				return res.status(403).json({
					success: false,
					message: "Insufficient permissions",
				});
			}

			next();
		};
	},
};
