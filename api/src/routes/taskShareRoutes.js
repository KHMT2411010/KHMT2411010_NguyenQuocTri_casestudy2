
const express = require("express");

const router = express.Router({ mergeParams: true });

const taskShareController = require("../controllers/taskShareController");
const authMiddleware = require("../middleware/authMiddleware");
const permissionMiddleware = require("../middleware/permissionMiddleware");

// Xac thuc nguoi dung
router.use(authMiddleware);

// Xem danh sach nguoi duoc chia se
router.get(
  "/",
  permissionMiddleware("view"),
  taskShareController.getShares
);

// Chia se cong viec
router.post(
  "/",
  permissionMiddleware("owner"),
  taskShareController.createShares
);

// Cap nhat quyen viewer/editor
router.patch(
  "/:shareId",
  permissionMiddleware("owner"),
  taskShareController.updateShare
);

// Thu hoi quyen chia se
router.delete(
  "/:shareId",
  permissionMiddleware("owner"),
  taskShareController.deleteShare
);

module.exports = router;
