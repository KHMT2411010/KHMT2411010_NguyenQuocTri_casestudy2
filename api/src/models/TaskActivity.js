const mongoose = require("mongoose");

const taskActivitySchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
      index: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    action: {
      type: String,
      required: true,
      enum: [
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
      ],
    },

    description: {
      type: String,
      default: "",
      trim: true,
      maxlength: 1000,
    },
  },
  {
    timestamps: true,
  }
);

taskActivitySchema.index({
  taskId: 1,
  createdAt: -1,
});

module.exports =
  mongoose.models.TaskActivity ||
  mongoose.model("TaskActivity", taskActivitySchema);