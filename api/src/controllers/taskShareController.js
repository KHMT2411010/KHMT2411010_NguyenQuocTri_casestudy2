const mongoose = require("mongoose");
const TaskShare = require("../models/TaskShare");
const { createTaskActivity } = require("../services/taskService");
const User = require("../models/User");
const { sendEmail } = require("../services/emailService");
const { createNotification } = require("../services/notificationService");

// GET /api/tasks/:id/shares
exports.getShares = async (req, res, next) => {
  try {
    const shares = await TaskShare.find({
      taskId: req.task._id,
    })
      .populate("userId", "fullName email")
      .populate("sharedBy", "fullName email");

    res.json({
      success: true,
      data: shares,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/tasks/:id/shares
 * D2 - Gui email khi moi nguoi dung chia se cong viec.
 */
exports.createShares = async (req, res, next) => {
  try {
    const { userIds, permission = "viewer" } = req.body;

    if (
      !Array.isArray(userIds) ||
      userIds.length === 0 ||
      !userIds.every((id) => mongoose.isValidObjectId(id))
    ) {
      return res.status(400).json({
        success: false,
        message: "Danh sách người dùng không hợp lệ",
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyền chia sẻ không hợp lệ",
      });
    }

    const ids = [...new Set(userIds.map(String))];

    if (ids.includes(String(req.task.createdBy))) {
      return res.status(400).json({
        success: false,
        message: "Không thể chia sẻ cho người tạo",
      });
    }

    const count = await User.countDocuments({
      _id: { $in: ids },
    });

    if (count !== ids.length) {
      return res.status(400).json({
        success: false,
        message: "Có người dùng không tồn tại",
      });
    }

    // Lay danh sach nguoi da duoc chia se truoc do.
    const existingShares = await TaskShare.find({
      taskId: req.task._id,
      userId: { $in: ids },
    }).select("userId permission");

    const existingIds = new Set(
      existingShares.map((share) => String(share.userId)),
    );

    const previousSharePermissions = new Map(
      existingShares.map((share) => [
        String(share.userId),
        share.permission,
      ]),
    );

    // Giu nguyen co che chia se va cap nhat quyen cua phan C.
    for (const userId of ids) {
      await TaskShare.updateOne(
        {
          taskId: req.task._id,
          userId,
        },
        {
          $set: {
            permission,
            sharedBy: req.user.id,
          },
        },
        { upsert: true },
      );
    }

    const shares = await TaskShare.find({
      taskId: req.task._id,
    });

    // D2: Chi gui email cho loi moi chia se moi.
    const newUserIds = ids.filter((id) => !existingIds.has(id));

    // E4: POST permission change history for existing shares.
    for (const userId of ids) {
      const oldPermission = previousSharePermissions.get(userId);

      if (!oldPermission || oldPermission === permission) {
        continue;
      }

      const activityResult = await createTaskActivity({
        taskId: req.task._id,
        userId: req.user.id,
        action: "share_updated",
        description:
          "Da thay doi quyen chia se cua nguoi dung: " +
          String(userId) +
          " (" +
          oldPermission +
          " -> " +
          permission +
          ")",
      });

      if (!activityResult.success) {
        console.error(
          "[E4] Could not record POST share_updated:",
          activityResult.error
        );
      }
    }

    // E4: Record history only for newly created shares.
    for (const newUserId of newUserIds) {
      const activityResult = await createTaskActivity({
        taskId: req.task._id,
        userId: req.user.id,
        action: "share_created",
        description:
          "Da chia se cong viec cho nguoi dung: " +
          String(newUserId) +
          " (quyen: " +
          permission +
          ")",
      });

      if (!activityResult.success) {
        console.error(
          "[E4] Could not record share_created:",
          activityResult.error
        );
      }
    }

    if (newUserIds.length > 0) {
      try {
        const newUsers = await User.find({
          _id: { $in: newUserIds },
        }).select("fullName email");

        for (const user of newUsers) {
          // D7: Tao thong bao cho nguoi moi duoc chia se.
          // Khong phu thuoc vao ket qua gui email.
          const notificationResult = await createNotification({
            userId: user._id,
            taskId: req.task._id,
            type: "task_shared",
            title: "Bạn được chia sẻ công việc mới",
            message:
              "Bạn được mời tham gia công việc: " +
              req.task.title +
              " (Quyền: " +
              permission +
              ")",
          });

          if (!notificationResult.success) {
            console.error("D7 share notification failed:", String(user._id));
          }

          // D2 + D6: Giu nguyen email va lich su gui email.
          const result = await sendEmail({
            to: user.email,
            taskId: req.task._id,
            userId: user._id,
            eventType: "task_shared",
            subject: "[TaskManager] Loi moi tham gia cong viec",

            text:
              "Xin chao " +
              user.fullName +
              ",\n\n" +
              "Ban vua duoc moi tham gia mot cong viec tren TaskManager.\n\n" +
              "Ten cong viec: " +
              req.task.title +
              "\n" +
              "Quyen truy cap: " +
              permission +
              "\n\n" +
              "Quyen viewer: Xem thong tin cong viec.\n" +
              "Quyen editor: Xem va chinh sua cong viec theo phan quyen.\n\n" +
              "Vui long dang nhap TaskManager de xem chi tiet.\n\n" +
              "TaskManager",
          });

          if (!result.success) {
            console.error("D2 email failed for user:", String(user._id));
          }
        }
      } catch (emailError) {
        console.error("D2 notification error:", emailError.message);
      }
    }

    res.status(201).json({
      success: true,
      message: "Chia sẻ thành công",
      data: shares,
    });
  } catch (error) {
    next(error);
  }
};
// PATCH /api/tasks/:id/shares/:shareId
exports.updateShare = async (req, res, next) => {
  try {
    const { shareId } = req.params;
    const { permission } = req.body;

    if (!mongoose.isValidObjectId(shareId)) {
      return res.status(400).json({
        success: false,
        message: "ID chia sẻ không hợp lệ",
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyền không hợp lệ",
      });
    }

    const previousShare = await TaskShare.findOne({
      _id: shareId,
      taskId: req.task._id,
    }).select("permission userId");

    const previousPermission = previousShare?.permission;

    const share = await TaskShare.findOneAndUpdate(
      {
        _id: shareId,
        taskId: req.task._id,
      },
      { permission },
      { new: true, runValidators: true },
    );

    if (!share) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy bản ghi chia sẻ",
      });
    }

    if (previousPermission && previousPermission !== permission) {
      const activityResult = await createTaskActivity({
        taskId: req.task._id,
        userId: req.user.id,
        action: "share_updated",
        description:
          "Da thay doi quyen chia se cua nguoi dung: " +
          String(share.userId) +
          " (" +
          previousPermission +
          " -> " +
          permission +
          ")",
      });

      if (!activityResult.success) {
        console.error(
          "[E4] Could not record share_updated:",
          activityResult.error
        );
      }
    }

    res.json({
      success: true,
      message: "Cập nhật quyền thành công",
      data: share,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/tasks/:id/shares/:shareId
exports.deleteShare = async (req, res, next) => {
  try {
    const { shareId } = req.params;

    if (!mongoose.isValidObjectId(shareId)) {
      return res.status(400).json({
        success: false,
        message: "ID chia sẻ không hợp lệ",
      });
    }

    const share = await TaskShare.findOneAndDelete({
      _id: shareId,
      taskId: req.task._id,
    });

    if (!share) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy bản ghi chia sẻ",
      });
    }

    // E4: Record history after successful share deletion.
    const activityResult = await createTaskActivity({
      taskId: req.task._id,
      userId: req.user.id,
      action: "share_removed",
      description:
        "Da thu hoi chia se cua nguoi dung: " +
        String(share.userId) +
        " (quyen cu: " +
        share.permission +
        ")",
    });

    if (!activityResult.success) {
      console.error(
        "[E4] Could not record share_removed:",
        activityResult.error
      );
    }

    res.json({
      success: true,
      message: "Thu hồi quyền thành công",
    });
  } catch (error) {
    next(error);
  }
};
