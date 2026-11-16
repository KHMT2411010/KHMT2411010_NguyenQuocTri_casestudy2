const mongoose = require("mongoose");

const emailLogSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      default: null,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    recipientEmail: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },

    eventType: {
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

    subject: {
      type: String,
      required: true,
    },

    status: {
      type: String,
      enum: ["sent", "failed"],
      required: true,
    },

    messageId: {
      type: String,
      default: "",
    },

    errorMessage: {
      type: String,
      default: "",
    },

    sentAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });
emailLogSchema.index({ userId: 1, createdAt: -1 });
emailLogSchema.index({ status: 1, createdAt: -1 });

module.exports =
  mongoose.models.EmailLog || mongoose.model("EmailLog", emailLogSchema);
