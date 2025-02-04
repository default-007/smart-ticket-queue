const express = require("express");
const router = express.Router();
const {
	createTicket,
	getTickets,
	getQueuedTickets,
	updateTicketStatus,
	processQueue,
} = require("../controllers/ticketController");
const auth = require("../middleware/auth");

router.use(auth); // Protect all routes

router.route("/").post(createTicket).get(getTickets);

router.get("/queue", getQueuedTickets);
router.put("/:id/status", updateTicketStatus);
router.post("/process-queue", processQueue);

module.exports = router;
