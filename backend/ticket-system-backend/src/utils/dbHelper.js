const safeDbOperation = async (
	operation,
	errorMessage = "Database operation failed"
) => {
	try {
		return await operation();
	} catch (error) {
		logger.error(`${errorMessage}: ${error.message}`);
		throw new Error(`${errorMessage}: ${error.message}`);
	}
};

// Usage example
const agent = await safeDbOperation(
	() => Agent.findById(agentId),
	`Failed to find agent with ID ${agentId}`
);
