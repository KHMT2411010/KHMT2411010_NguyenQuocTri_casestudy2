const mongoose = require("mongoose");
const Notification = require("../models/Notification");

async function createNotification({
  userId,
  taskId,
  type,
  title,
  message,
  reminderId = null,
}) {
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

    const data = {
      userId,
      taskId,
      type,
      title,
      message,
      isRead: false,
      readAt: null,
    };

    if (type === "task_reminder") {
      if (!mongoose.isValidObjectId(reminderId)) {
        throw new Error("Invalid notification reminderId");
      }

      const notification = await Notification.findOneAndUpdate(
        { reminderId },
        {
          $setOnInsert: {
            ...data,
            reminderId,
          },
        },
        {
          upsert: true,
          new: true,
          setDefaultsOnInsert: true,
        },
      );

      return {
        success: true,
        notification,
      };
    }

    if (reminderId != null) {
      throw new Error("reminderId is only allowed for task_reminder");
    }

    const notification = await Notification.create(data);

    return {
      success: true,
      notification,
    };
  } catch (error) {
    if (type === "task_reminder" && error.code === 11000 && reminderId) {
      try {
        const existing = await Notification.findOne({ reminderId });

        if (existing) {
          return {
            success: true,
            notification: existing,
          };
        }
      } catch (lookupError) {
        console.error(
          "D7 reminder notification lookup error:",
          lookupError.message,
        );
      }
    }

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
