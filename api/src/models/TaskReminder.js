const mongoose = require("mongoose");

const taskReminderSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    dueDate: {
      type: Date,
      required: true,
    },

    reminderHours: {
      type: Number,
      required: true,
      default: 24,
    },

    status: {
      type: String,
      enum: ["pending", "sending", "sent", "failed"],
      default: "pending",
    },

    sentAt: {
      type: Date,
      default: null,
    },

    attempts: {
      type: Number,
      default: 0,
    },

    lastError: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  },
);

// Moi nguoi chi co mot ban ghi cho mot moc nhac viec.
taskReminderSchema.index(
  {
    taskId: 1,
    userId: 1,
    dueDate: 1,
    reminderHours: 1,
  },
  { unique: true },
);

module.exports =
  mongoose.models.TaskReminder ||
  mongoose.model("TaskReminder", taskReminderSchema);
