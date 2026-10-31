
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
          message: "ID công việc không hợp lệ"
        });
      }

      const task = await Task.findById(taskId);

      if (!task) {
        return res.status(404).json({
          success: false,
          message: "Không tìm thấy công việc"
        });
      }

      const isOwner =
        String(task.createdBy) === String(userId);

      const isAssignee = task.assigneeIds.some(
        id => String(id) === String(userId)
      );

      const share = await TaskShare.findOne({
        taskId,
        userId
      });

      let allowed = false;

      if (isOwner) {
        allowed = true;
      } else if (requiredPermission === "view") {
        allowed = isAssignee || Boolean(share);
      } else if (requiredPermission === "edit") {
        allowed = share?.permission === "editor";
      } else if (requiredPermission === "status") {
        allowed = isAssignee ||
          share?.permission === "editor";
      }

      if (!allowed) {
        return res.status(403).json({
          success: false,
          message: "Bạn không có quyền thực hiện"
        });
      }

      req.task = task;
      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = permissionMiddleware;
