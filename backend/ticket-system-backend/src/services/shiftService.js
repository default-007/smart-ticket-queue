const Shift = require("../models/Shift");
const Agent = require("../models/Agent");
const mongoose = require("mongoose");

class ShiftService {
	async startShift(agentId) {
		try {
			const agent = await Agent.findById(agentId);
			if (!agent) {
				throw new Error("Agent not found");
			}

			// Check if agent already has an active shift
			const existingActiveShift = await Shift.findOne({
				agent: agentId,
				status: "in-progress",
			});

			if (existingActiveShift) {
				throw new Error("An active shift is already in progress");
			}

			const shift = new Shift({
				agent: agentId,
				start: new Date(),
				end: new Date(Date.now() + 8 * 60 * 60 * 1000), // 8-hour shift
				status: "in-progress",
			});

			await shift.save();

			// Update agent status
			agent.status = "online";
			await agent.save();

			return shift;
		} catch (error) {
			throw error;
		}
	}

	async endShift(shiftId) {
		try {
			const shift = await Shift.findById(shiftId).populate("agent");
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

			await shift.save();

			// Update agent status
			const agent = shift.agent;
			agent.status = "offline";
			await agent.save();

			return shift;
		} catch (error) {
			throw error;
		}
	}

	async scheduleBreak(shiftId, breakData) {
		try {
			const shift = await Shift.findById(shiftId);
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

			await shift.save();

			return shift;
		} catch (error) {
			throw error;
		}
	}

	async startBreak(shiftId, breakId) {
		try {
			const shift = await Shift.findById(shiftId);
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

			await shift.save();

			return shift;
		} catch (error) {
			throw error;
		}
	}

	async endBreak(shiftId, breakId) {
		try {
			const shift = await Shift.findById(shiftId);
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

			await shift.save();

			return shift;
		} catch (error) {
			throw error;
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
