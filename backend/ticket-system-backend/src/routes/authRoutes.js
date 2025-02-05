const express = require("express");
const router = express.Router();
const {
	register,
	login,
	getMe,
	updateProfile,
	changePassword,
	logout,
} = require("../controllers/authController");
const auth = require("../middleware/auth");
const { checkPermission } = require("../middleware/auth");

// Public routes
router.post("/register", register);
router.post("/login", login);

// Protected routes
router.get("/me", auth, getMe);
router.put("/profile", auth, updateProfile);
router.put("/change-password", auth, changePassword);
router.post("/logout", auth, logout);

router.get("/test", (req, res) => {
	res.json({ message: "API is working!" });
});

module.exports = router;
