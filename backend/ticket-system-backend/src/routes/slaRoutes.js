const express = require("express");
const router = express.Router();
const {
	getSLAMetrics,
	getSLAConfig,
	updateSLAConfig,
	checkTicketSLA,
} = require("../controllers/slaController");
const auth = require("../middleware/auth");
const authorize = require("../middleware/authorize");

router.use(auth);

router.get("/metrics", authorize("admin", "supervisor"), getSLAMetrics);
router.get("/config", getSLAConfig);
//router.get("/config/:priority/:category", getSLAConfig);
router.put("/config/:priority/:category", authorize("admin"), updateSLAConfig);
router.get("/check/:ticketId", checkTicketSLA);

module.exports = router;
