const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const notificationController = require("../controllers/notificationController");

// Tat ca API thong bao deu yeu cau dang nhap.
router.use(authMiddleware);

// Lay danh sach thong bao cua tai khoan hien tai.
router.get("/", notificationController.getNotifications);

// Dem so thong bao chua doc.
router.get("/unread-count", notificationController.getUnreadCount);

// Danh dau tat ca thong bao da doc.
router.patch("/read-all", notificationController.markAllAsRead);

// Danh dau mot thong bao da doc.
router.patch("/:id/read", notificationController.markAsRead);

module.exports = router;
