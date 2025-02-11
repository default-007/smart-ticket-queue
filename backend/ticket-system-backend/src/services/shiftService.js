const Shift = require("../models/Shift");
const Agent = require("../models/Agent");
const mongoose = require("mongoose");

class ShiftService {
	async startShift(agentId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const agent = await Agent.findById(agentId).session(session);
			if (!agent) {
				throw new Error("Agent not found");
			}

			// Check if agent already has an active shift
			const existingActiveShift = await Shift.findOne({
				agent: agentId,
				status: "in-progress",
			}).session(session);

			if (existingActiveShift) {
				throw new Error("An active shift is already in progress");
			}

			const shift = new Shift({
				agent: agentId,
				start: new Date(),
				end: new Date(Date.now() + 8 * 60 * 60 * 1000), // 8-hour shift
				status: "in-progress",
			});

			await shift.save({ session });

			// Update agent status
			agent.status = "online";
			await agent.save({ session });

			await session.commitTransaction();
			return shift;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async endShift(shiftId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const shift = await Shift.findById(shiftId)
				.populate("agent")
				.session(session);

			if (!shift) {
				throw new Error("Shift not found");
			}

			// Complete any ongoing breaks
			shift.breaks.forEach((breakItem) => {
				if (breakItem.status === "in-progress") {
					breakItem.status = "completed";
					breakItem.end = new Date();
				}
			});

			shift.status = "completed";
			shift.end = new Date();

			await shift.save({ session });

			// Update agent status
			const agent = shift.agent;
			agent.status = "offline";
			await agent.save({ session });

			await session.commitTransaction();
			return shift;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async scheduleBreak(shiftId, breakData) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const shift = await Shift.findById(shiftId).session(session);
			if (!shift) {
				throw new Error("Shift not found");
			}

			// Validate break timing
			const breakStart = new Date(breakData.start);
			const breakEnd = new Date(breakData.end);

			if (breakStart >= breakEnd) {
				throw new Error("Invalid break timing");
			}

			if (breakStart < shift.start || breakEnd > shift.end) {
				throw new Error("Break is outside shift hours");
			}

			shift.breaks.push({
				type: breakData.type,
				start: breakStart,
				end: breakEnd,
				status: "scheduled",
			});

			await shift.save({ session });
			await session.commitTransaction();
			return shift;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async startBreak(shiftId, breakId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const shift = await Shift.findById(shiftId).session(session);
			if (!shift) {
				throw new Error("Shift not found");
			}

			const breakItem = shift.breaks.id(breakId);
			if (!breakItem) {
				throw new Error("Break not found");
			}

			if (breakItem.status !== "scheduled") {
				throw new Error("Break cannot be started");
			}

			breakItem.status = "in-progress";
			breakItem.start = new Date();

			await shift.save({ session });
			await session.commitTransaction();
			return shift;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async endBreak(shiftId, breakId) {
		const session = await mongoose.startSession();
		try {
			session.startTransaction();

			const shift = await Shift.findById(shiftId).session(session);
			if (!shift) {
				throw new Error("Shift not found");
			}

			const breakItem = shift.breaks.id(breakId);
			if (!breakItem) {
				throw new Error("Break not found");
			}

			if (breakItem.status !== "in-progress") {
				throw new Error("Break cannot be ended");
			}

			breakItem.status = "completed";
			breakItem.end = new Date();

			await shift.save({ session });
			await session.commitTransaction();
			return shift;
		} catch (error) {
			await session.abortTransaction();
			throw error;
		} finally {
			session.endSession();
		}
	}

	async getAgentShifts(agentId, options = {}) {
		const { startDate, endDate, status } = options;

		const query = { agent: agentId };

		if (startDate) {
			query.start = { $gte: new Date(startDate) };
		}

		if (endDate) {
			query.end = { $lte: new Date(endDate) };
		}

		if (status) {
			query.status = status;
		}

		return await Shift.find(query)
			.sort({ start: -1 })
			.populate("agent", "name email department");
	}
}

module.exports = new ShiftService();
