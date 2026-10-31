
const express = require("express");
const router = express.Router();

const taskController = require("../controllers/taskController");
const authMiddleware = require("../middleware/authMiddleware");
const permissionMiddleware = require("../middleware/permissionMiddleware");

// Tất cả API công việc đều yêu cầu đăng nhập
router.use(authMiddleware);

// Danh sách công việc
router.get("/", taskController.getTasks);

// Tạo công việc
router.post("/", taskController.createTask);

// Xem chi tiết công việc
router.get(
  "/:id",
  permissionMiddleware("view"),
  taskController.getTaskById
);

// Chỉnh sửa công việc
router.put(
  "/:id",
  permissionMiddleware("edit"),
  taskController.updateTask
);

// Cập nhật trạng thái
router.patch(
  "/:id/status",
  permissionMiddleware("status"),
  taskController.updateStatus
);

// Xóa công việc
router.delete(
  "/:id",
  permissionMiddleware("owner"),
  taskController.deleteTask
);

module.exports = router;
