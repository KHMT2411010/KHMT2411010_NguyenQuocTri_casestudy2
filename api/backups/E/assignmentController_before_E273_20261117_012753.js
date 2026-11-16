const mongoose = require("mongoose");
const Task = require("../models/Task");
const User = require("../models/User");
const { sendEmail } = require("../services/emailService");
const { createNotification } = require("../services/notificationService");

// GET /api/tasks/:id/assignees
exports.getAssignees = async (req, res, next) => {
  try {
    const task = await Task.findById(req.task._id)
      .populate("assigneeIds", "fullName email")
      .populate("primaryAssigneeId", "fullName email");

    res.json({
      success: true,
      data: {
        assignees: task.assigneeIds,
        primaryAssignee: task.primaryAssigneeId,
      },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/tasks/:id/assignees
exports.assignUsers = async (req, res, next) => {
  try {
    const { userIds, primaryAssigneeId } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng chọn người được giao",
      });
    }

    if (!userIds.every((id) => mongoose.isValidObjectId(id))) {
      return res.status(400).json({
        success: false,
        message: "ID người dùng không hợp lệ",
      });
    }

    const task = req.task;

    const existingAssigneeIds = new Set(
      task.assigneeIds.map((id) => String(id)),
    );

    const newAssigneeIds = [...new Set(userIds.map(String))].filter(
      (id) => !existingAssigneeIds.has(id),
    );

    const ids = [
      ...new Set([...task.assigneeIds.map(String), ...userIds.map(String)]),
    ];

    const count = await User.countDocuments({
      _id: { $in: ids },
    });

    if (count !== ids.length) {
      return res.status(400).json({
        success: false,
        message: "Có người dùng không tồn tại",
      });
    }

    if (primaryAssigneeId != null && !ids.includes(String(primaryAssigneeId))) {
      return res.status(400).json({
        success: false,
        message: "Người phụ trách chính không hợp lệ",
      });
    }

    task.assigneeIds = ids;

    if (primaryAssigneeId) {
      task.primaryAssigneeId = primaryAssigneeId;
    } else if (!task.primaryAssigneeId) {
      task.primaryAssigneeId = ids[0];
    }

    await task.save();

    // D1 va D7: Xu ly nguoi moi duoc giao.
    if (newAssigneeIds.length > 0) {
      try {
        const newAssignees = await User.find({
          _id: { $in: newAssigneeIds },
        }).select("fullName email");

        for (const user of newAssignees) {
          // D7: Tao thong bao doc lap voi ket qua gui email.
          const notificationResult = await createNotification({
            userId: user._id,
            taskId: task._id,
            type: "task_assigned",
            title: "Bạn được giao công việc mới",
            message: "Bạn vừa được giao công việc: " + task.title,
          });

          if (!notificationResult.success) {
            console.error(
              "D7 notification failed for assignee:",
              String(user._id),
            );
          }

          // D1 + D6: Gui email va luu EmailLog.
          const result = await sendEmail({
            to: user.email,
            taskId: task._id,
            userId: user._id,
            eventType: "task_assigned",
            subject: "[TaskManager] Ban duoc giao cong viec moi",
            text:
              "Xin chao " +
              user.fullName +
              ",\n\n" +
              "Ban vua duoc giao mot cong viec moi tren TaskManager.\n\n" +
              "Ten cong viec: " +
              task.title +
              "\n" +
              "Trang thai: " +
              task.status +
              "\n" +
              "Muc do uu tien: " +
              task.priority +
              "\n\n" +
              "Vui long dang nhap TaskManager de xem chi tiet.\n\n" +
              "TaskManager",
          });

          if (!result.success) {
            console.error("D1 email failed for assignee:", String(user._id));
          }
        }
      } catch (notificationError) {
        console.error("D1/D7 notification error:", notificationError.message);
      }
    }

    res.json({
      success: true,
      message: "Giao công việc thành công",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/tasks/:id/assignees/:userId
exports.updateAssignee = async (req, res, next) => {
  try {
    const { userId } = req.params;

    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "ID người dùng không hợp lệ",
      });
    }

    const task = req.task;

    const exists = task.assigneeIds.some((id) => String(id) === userId);

    if (!exists) {
      return res.status(404).json({
        success: false,
        message: "Người dùng chưa được giao việc",
      });
    }

    if (req.body.isPrimary !== true) {
      return res.status(400).json({
        success: false,
        message: "Cần truyền isPrimary: true",
      });
    }

    task.primaryAssigneeId = userId;
    await task.save();

    res.json({
      success: true,
      message: "Cập nhật người phụ trách thành công",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/tasks/:id/assignees/:userId
exports.removeAssignee = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const task = req.task;

    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "ID người dùng không hợp lệ",
      });
    }

    const exists = task.assigneeIds.some((id) => String(id) === userId);

    if (!exists) {
      return res.status(404).json({
        success: false,
        message: "Người dùng chưa được giao việc",
      });
    }

    task.assigneeIds = task.assigneeIds.filter((id) => String(id) !== userId);

    if (String(task.primaryAssigneeId) === userId) {
      task.primaryAssigneeId = task.assigneeIds[0] || null;
    }

    await task.save();

    res.json({
      success: true,
      message: "Hủy giao việc thành công",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};
