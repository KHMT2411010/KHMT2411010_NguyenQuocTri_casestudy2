const mongoose = require("mongoose");
const Notification = require("../models/Notification");

async function createNotification({ userId, taskId, type, title, message }) {
  try {
    if (!mongoose.isValidObjectId(userId)) {
      throw new Error("Invalid notification userId");
    }

    if (!mongoose.isValidObjectId(taskId)) {
      throw new Error("Invalid notification taskId");
    }

    if (!type || !title || !message) {
      throw new Error("Missing notification information");
    }

    const notification = await Notification.create({
      userId,
      taskId,
      type,
      title,
      message,
      isRead: false,
      readAt: null,
    });

    return {
      success: true,
      notification,
    };
  } catch (error) {
    console.error("D7 notification error:", error.message);

    return {
      success: false,
      error: error.message,
    };
  }
}

module.exports = {
  createNotification,
};
