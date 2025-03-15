// middleware/adminOnly.js
const adminOnly = (req, res, next) => {
	if (!req.user || req.user.role !== "admin") {
		return res.status(403).json({
			success: false,
			message: "This action requires administrator privileges",
		});
	}
	next();
};

module.exports = adminOnly;
