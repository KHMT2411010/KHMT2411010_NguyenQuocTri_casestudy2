
const mongoose = require("mongoose");
const TaskShare = require("../models/TaskShare");
const User = require("../models/User");

// GET /api/tasks/:id/shares
exports.getShares = async (req, res, next) => {
  try {
    const shares = await TaskShare.find({
      taskId: req.task._id
    })
      .populate("userId", "fullName email")
      .populate("sharedBy", "fullName email");

    res.json({
      success: true,
      data: shares
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/tasks/:id/shares
exports.createShares = async (req, res, next) => {
  try {
    const { userIds, permission = "viewer" } = req.body;

    if (
      !Array.isArray(userIds) ||
      userIds.length === 0 ||
      !userIds.every(id => mongoose.isValidObjectId(id))
    ) {
      return res.status(400).json({
        success: false,
        message: "Danh sách người dùng không hợp lệ"
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyền chia sẻ không hợp lệ"
      });
    }

    const ids = [...new Set(userIds.map(String))];

    if (ids.includes(String(req.task.createdBy))) {
      return res.status(400).json({
        success: false,
        message: "Không thể chia sẻ cho người tạo"
      });
    }

    const count = await User.countDocuments({
      _id: { $in: ids }
    });

    if (count !== ids.length) {
      return res.status(400).json({
        success: false,
        message: "Có người dùng không tồn tại"
      });
    }

    for (const userId of ids) {
      await TaskShare.updateOne(
        {
          taskId: req.task._id,
          userId
        },
        {
          $set: {
            permission,
            sharedBy: req.user.id
          }
        },
        { upsert: true }
      );
    }

    const shares = await TaskShare.find({
      taskId: req.task._id
    });

    res.status(201).json({
      success: true,
      message: "Chia sẻ thành công",
      data: shares
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
        message: "ID chia sẻ không hợp lệ"
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyền không hợp lệ"
      });
    }

    const share = await TaskShare.findOneAndUpdate(
      {
        _id: shareId,
        taskId: req.task._id
      },
      { permission },
      { new: true, runValidators: true }
    );

    if (!share) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy bản ghi chia sẻ"
      });
    }

    res.json({
      success: true,
      message: "Cập nhật quyền thành công",
      data: share
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
        message: "ID chia sẻ không hợp lệ"
      });
    }

    const share = await TaskShare.findOneAndDelete({
      _id: shareId,
      taskId: req.task._id
    });

    if (!share) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy bản ghi chia sẻ"
      });
    }

    res.json({
      success: true,
      message: "Thu hồi quyền thành công"
    });
  } catch (error) {
    next(error);
  }
};
