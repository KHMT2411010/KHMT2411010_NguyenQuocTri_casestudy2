const express = require("express");
const router = express.Router();

const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

// Đăng ký
router.post("/register", authController.register);

// Đăng nhập
router.post("/login", authController.login);

// Xem thông tin cá nhân
router.get("/me", authMiddleware, authController.me);

// Cập nhật thông tin cá nhân
router.put("/me", authMiddleware, authController.updateProfile);

// Đổi mật khẩu
router.put("/change-password", authMiddleware, authController.changePassword);

module.exports = router;
