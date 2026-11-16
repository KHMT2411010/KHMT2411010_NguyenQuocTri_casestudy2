const mongoose = require("mongoose");
const TaskActivity = require("../models/TaskActivity");

const VALID_ACTIONS = new Set([
  "task_created",
  "task_updated",
  "task_status_changed",
  "task_deleted",
  "assignee_added",
  "assignee_updated",
  "assignee_removed",
  "share_created",
  "share_updated",
  "share_removed",
]);

async function createTaskActivity({
  taskId,
  userId,
  action,
  description = "",
}) {
  try {
    if (
      !mongoose.isValidObjectId(taskId) ||
      !mongoose.isValidObjectId(userId)
    ) {
      return {
        success: false,
        error: "Invalid taskId or userId",
      };
    }

    if (!VALID_ACTIONS.has(action)) {
      return {
        success: false,
        error: "Invalid activity action",
      };
    }

    const activity = await TaskActivity.create({
      taskId,
      userId,
      action,
      description: String(description).slice(0, 1000),
    });

    return {
      success: true,
      activity,
    };
  } catch (error) {
    console.error(
      "[TaskActivity] Failed to save activity:",
      error.message
    );

    return {
      success: false,
      error: error.message,
    };
  }
}

module.exports = {
  createTaskActivity,
};