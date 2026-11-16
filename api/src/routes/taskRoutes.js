const express = require("express");
const router = express.Router();

const taskController = require("../controllers/taskController");
const taskActivityController = require("../controllers/taskActivityController");
const authMiddleware = require("../middleware/authMiddleware");
const permissionMiddleware = require("../middleware/permissionMiddleware");

// Tất cả API công việc đều yêu cầu đăng nhập
router.use(authMiddleware);

// Danh sách công việc
router.get("/", taskController.getTasks);

// Tạo công việc
router.post("/", taskController.createTask);

// Xem lịch sử hoạt động của công việc (yêu cầu quyền xem)
router.get(
  "/:id/activities",
  permissionMiddleware("view"),
  taskActivityController.getTaskActivities,
);

// Xem chi tiết công việc
router.get("/:id", permissionMiddleware("view"), taskController.getTaskById);

// Chỉnh sửa công việc
router.put("/:id", permissionMiddleware("edit"), taskController.updateTask);

// Cập nhật trạng thái
router.patch(
  "/:id/status",
  permissionMiddleware("status"),
  taskController.updateStatus,
);

// Xóa công việc: người tạo hoặc người được giao
router.delete(
  "/:id",
  permissionMiddleware("manage"),
  taskController.deleteTask,
);

module.exports = router;
