
const express = require("express");
const router = express.Router();

const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

// Đăng ký
router.post("/register", authController.register);

// Đăng nhập
router.post("/login", authController.login);

// Lấy thông tin tài khoản
router.get("/me", authMiddleware, authController.me);

module.exports = router;
