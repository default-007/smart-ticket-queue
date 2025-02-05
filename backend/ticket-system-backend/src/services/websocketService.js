const socketIo = require("socket.io");
const jwt = require("jsonwebtoken");

class WebSocketService {
	constructor(server) {
		this.io = socketIo(server, {
			cors: {
				origin: process.env.CLIENT_URL,
				methods: ["GET", "POST"],
			},
		});

		this.setupSocketAuth();
		this.setupEventHandlers();
	}

	setupSocketAuth() {
		this.io.use((socket, next) => {
			if (socket.handshake.auth && socket.handshake.auth.token) {
				jwt.verify(
					socket.handshake.auth.token,
					process.env.JWT_SECRET,
					(err, decoded) => {
						if (err) return next(new Error("Authentication error"));
						socket.user = decoded;
						next();
					}
				);
			} else {
				next(new Error("Authentication error"));
			}
		});
	}

	setupEventHandlers() {
		this.io.on("connection", (socket) => {
			console.log(`User connected: ${socket.user.id}`);

			// Join user's personal room
			socket.join(socket.user.id);

			// Join department room if agent
			if (socket.user.role === "agent") {
				socket.join(`department:${socket.user.department}`);
			}

			socket.on("disconnect", () => {
				console.log(`User disconnected: ${socket.user.id}`);
			});

			// Handle ticket updates
			socket.on("ticket:update", (data) => {
				socket.to(`department:${data.department}`).emit("ticket:updated", data);
			});

			// Handle agent status updates
			socket.on("agent:status_update", (data) => {
				socket
					.to(`department:${data.department}`)
					.emit("agent:status_updated", data);
			});
		});
	}

	// Notification methods
	notifyTicketAssigned(ticketId, agentId, ticketData) {
		this.io.to(agentId).emit("ticket:assigned", { ticketId, ...ticketData });
	}

	notifySLABreach(ticketId, departmentId, breachData) {
		this.io.to(`department:${departmentId}`).emit("sla:breach", {
			ticketId,
			...breachData,
		});
	}

	notifyShiftEnding(agentId, shiftData) {
		this.io.to(agentId).emit("shift:ending", shiftData);
	}

	notifyWorkloadUpdate(departmentId, workloadData) {
		this.io
			.to(`department:${departmentId}`)
			.emit("workload:updated", workloadData);
	}

	notifyQueueUpdate(departmentId, queueData) {
		this.io.to(`department:${departmentId}`).emit("queue:updated", queueData);
	}

	broadcastDepartmentMessage(departmentId, message) {
		this.io
			.to(`department:${departmentId}`)
			.emit("department:message", message);
	}

	// Helper methods
	emitToUser(userId, event, data) {
		this.io.to(userId).emit(event, data);
	}

	emitToDepartment(departmentId, event, data) {
		this.io.to(`department:${departmentId}`).emit(event, data);
	}

	broadcastSystemMessage(message) {
		this.io.emit("system:message", message);
	}
}

module.exports = WebSocketService;
