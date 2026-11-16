const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
    },

    reminderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "TaskReminder",
      default: null,
    },
    type: {
      type: String,
      enum: [
        "task_assigned",
        "task_shared",
        "task_updated",
        "task_completed",
        "task_reminder",
      ],
      required: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    message: {
      type: String,
      required: true,
      trim: true,
    },

    isRead: {
      type: Boolean,
      default: false,
    },

    readAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index(
  { reminderId: 1 },
  {
    unique: true,
    partialFilterExpression: {
      reminderId: { $type: "objectId" },
    },
  },
);

module.exports =
  mongoose.models.Notification ||
  mongoose.model("Notification", notificationSchema);
