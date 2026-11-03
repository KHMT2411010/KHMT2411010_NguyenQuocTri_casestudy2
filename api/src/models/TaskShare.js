
const mongoose = require("mongoose");

const taskShareSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    permission: {
      type: String,
      enum: ["viewer", "editor"],
      default: "viewer"
    },

    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    }
  },
  {
    timestamps: true
  }
);

// Không cho phép chia sẻ trùng một công việc cho cùng người dùng
taskShareSchema.index(
  { taskId: 1, userId: 1 },
  { unique: true }
);

module.exports =
  mongoose.models.TaskShare ||
  mongoose.model("TaskShare", taskShareSchema);
