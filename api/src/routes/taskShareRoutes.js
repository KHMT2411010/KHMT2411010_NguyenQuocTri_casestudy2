
const express = require("express");

const router = express.Router({ mergeParams: true });

const taskShareController = require("../controllers/taskShareController");
const authMiddleware = require("../middleware/authMiddleware");
const permissionMiddleware = require("../middleware/permissionMiddleware");

// Tat ca API chia se deu yeu cau dang nhap.
router.use(authMiddleware);

// Xem danh sach nguoi duoc chia se.
// Owner, Assignee, Editor va Viewer duoc xem.
router.get(
  "/",
  permissionMiddleware("view"),
  taskShareController.getShares
);

// Chia se cong viec.
// Chi Owner va Assignee duoc phep.
router.post(
  "/",
  permissionMiddleware("manage"),
  taskShareController.createShares
);

// Cap nhat quyen Viewer/Editor.
// Chi Owner va Assignee duoc phep.
router.patch(
  "/:shareId",
  permissionMiddleware("manage"),
  taskShareController.updateShare
);

// Thu hoi quyen chia se.
// Chi Owner va Assignee duoc phep.
router.delete(
  "/:shareId",
  permissionMiddleware("manage"),
  taskShareController.deleteShare
);

module.exports = router;
