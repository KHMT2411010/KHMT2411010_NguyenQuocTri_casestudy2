const mongoose = require("mongoose");
const Notification = require("../models/Notification");

// GET /api/notifications
exports.getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({
      userId: req.user.id,
    })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    res.json({
      success: true,
      data: notifications,
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.user.id,
      isRead: false,
    });

    res.json({
      success: true,
      data: {
        unreadCount: count,
      },
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/notifications/:id/read
exports.markAsRead = async (req, res, next) => {
  try {
    const notificationId = req.params.id;

    if (!mongoose.isValidObjectId(notificationId)) {
      return res.status(400).json({
        success: false,
        message: "ID thông báo không hợp lệ",
      });
    }

    const notification = await Notification.findOneAndUpdate(
      {
        _id: notificationId,
        userId: req.user.id,
        isRead: false,
      },
      {
        $set: {
          isRead: true,
          readAt: new Date(),
        },
      },
      {
        returnDocument: "after",
      },
    );

    if (notification) {
      return res.json({
        success: true,
        message: "Đã đánh dấu thông báo đã đọc",
        data: notification,
      });
    }

    const existing = await Notification.findOne({
      _id: notificationId,
      userId: req.user.id,
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thông báo",
      });
    }

    return res.json({
      success: true,
      message: "Thông báo đã được đọc trước đó",
      data: existing,
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/notifications/read-all
exports.markAllAsRead = async (req, res, next) => {
  try {
    const result = await Notification.updateMany(
      {
        userId: req.user.id,
        isRead: false,
      },
      {
        $set: {
          isRead: true,
          readAt: new Date(),
        },
      },
    );

    res.json({
      success: true,
      message: "Đã đánh dấu tất cả thông báo đã đọc",
      data: {
        modifiedCount: result.modifiedCount,
      },
    });
  } catch (error) {
    next(error);
  }
};
