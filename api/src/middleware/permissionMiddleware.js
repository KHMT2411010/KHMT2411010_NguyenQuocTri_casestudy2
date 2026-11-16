const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");

const permissionMiddleware = (requiredPermission) => {
  return async (req, res, next) => {
    try {
      const taskId = req.params.id;
      const userId = req.user.id;

      if (!mongoose.isValidObjectId(taskId)) {
        return res.status(400).json({
          success: false,
          message: "ID công việc không hợp lệ",
        });
      }

      const task = await Task.findById(taskId);

      if (!task) {
        return res.status(404).json({
          success: false,
          message: "Không tìm thấy công việc",
        });
      }

      const isOwner = String(task.createdBy) === String(userId);

      const isAssignee =
        Array.isArray(task.assigneeIds) &&
        task.assigneeIds.some((id) => String(id) === String(userId));

      let share = null;

      if (!isOwner && !isAssignee) {
        share = await TaskShare.findOne({
          taskId: task._id,
          userId,
        });
      }

      const isEditor = share?.permission === "editor";
      const isViewer = share?.permission === "viewer";

      let allowed = false;

      switch (requiredPermission) {
        case "view":
          allowed = isOwner || isAssignee || isEditor || isViewer;
          break;

        case "edit":
          allowed = isOwner || isAssignee || isEditor;
          break;

        case "status":
          allowed = isOwner || isAssignee;
          break;

        case "manage":
          allowed = isOwner || isAssignee;
          break;

        case "owner":
          allowed = isOwner;
          break;

        default:
          allowed = false;
      }

      if (!allowed) {
        return res.status(403).json({
          success: false,
          message: "Bạn không có quyền thực hiện",
        });
      }

      req.task = task;

      req.taskRole = isOwner
        ? "owner"
        : isAssignee
          ? "assignee"
          : isEditor
            ? "editor"
            : "viewer";

      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = permissionMiddleware;
