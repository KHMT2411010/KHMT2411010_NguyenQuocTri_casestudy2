const express = require("express");
const router = express.Router({ mergeParams: true });

const assignmentController = require("../controllers/assignmentController");
const authMiddleware = require("../middleware/authMiddleware");
const permissionMiddleware = require("../middleware/permissionMiddleware");

router.use(authMiddleware);

// Danh sách người được giao
router.get(
  "/",
  permissionMiddleware("view"),
  assignmentController.getAssignees,
);

// Giao việc cho nhiều người
router.post(
  "/",
  permissionMiddleware("owner"),
  assignmentController.assignUsers,
);

// Thay đổi người phụ trách chính
router.patch(
  "/:userId",
  permissionMiddleware("owner"),
  assignmentController.updateAssignee,
);

// Hủy giao việc
router.delete(
  "/:userId",
  permissionMiddleware("owner"),
  assignmentController.removeAssignee,
);

module.exports = router;
