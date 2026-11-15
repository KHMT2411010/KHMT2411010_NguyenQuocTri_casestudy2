
const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");


﻿// GET /api/tasks
exports.getTasks = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const scope = String(req.query.scope || "all").trim();
    const status = String(req.query.status || "").trim();
    const priority = String(req.query.priority || "").trim();
    const assigneeId = String(req.query.assigneeId || "").trim();
    const sortBy = String(req.query.sortBy || "createdAt").trim();
    const sortOrder = String(req.query.sortOrder || "desc").trim();
    if (
      assigneeId &&
      assigneeId !== "me" &&
      !mongoose.isValidObjectId(assigneeId)
    ) {
      return res.status(400).json({
        success: false,
        message: "Nguoi phu trach khong hop le"
      });
    }

    const validScopes = ["all", "created", "assigned", "shared"];
    const validStatuses = ["todo", "in_progress", "completed"];
    const validPriorities = ["low", "medium", "high"];
    const validSortFields = ["createdAt", "dueDate", "priority"];
    const validSortOrders = ["asc", "desc"];


    if (
    !validSortFields.includes(sortBy) ||
    !validSortOrders.includes(sortOrder)
    ) {
    return res.status(400).json({
    success: false,
    message: "Tieu chi sap xep khong hop le"
    });
    }

    if (!validScopes.includes(scope)) {
      return res.status(400).json({
        success: false,
        message: "Bo loc cong viec khong hop le"
      });
    }

    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Trang thai khong hop le"
      });
    }

    if (priority && !validPriorities.includes(priority)) {
      return res.status(400).json({
        success: false,
        message: "Muc do uu tien khong hop le"
      });
    }

    let filter;

    if (scope === "created") {
      filter = { createdBy: userId };
    } else if (scope === "assigned") {
      filter = { assigneeIds: userId };
    } else {
      const shares = await TaskShare.find({
        userId: userId
      }).select("taskId");

      const sharedIds = shares.map((share) => share.taskId);

      if (scope === "shared") {
        filter = { _id: { $in: sharedIds } };
      } else {
        filter = {
          $or: [
            { createdBy: userId },
            { assigneeIds: userId },
            { _id: { $in: sharedIds } }
          ]
        };
      }
    }

    // Bo sung dieu kien loc, khong thay doi phan quyen truy cap.
    if (status) {
      filter.status = status;
    }

    if (priority) {
      filter.priority = priority;
    }


if (assigneeId === "me") {
  filter = {
    $and: [
      filter,
      {
        $or: [
          { createdBy: userId },
          { assigneeIds: userId }
        ]
      }
    ]
  };
} else if (assigneeId) {
  filter.assigneeIds = assigneeId;
}


    const tasks = await Task.find(filter)
      .populate("createdBy", "fullName email")
      .populate("assigneeIds", "fullName email")
      .populate("primaryAssigneeId", "fullName email")
      .sort({ createdAt: -1 });


    // B7: Sap xep danh sach sau khi ap dung bo loc B6.
    const priorityRank = {
    low: 1,
    medium: 2,
    high: 3
    };

    tasks.sort((a, b) => {
    let comparison = 0;

    if (sortBy === "priority") {
    comparison =
    (priorityRank[a.priority] ?? 0) -
    (priorityRank[b.priority] ?? 0);
    } else {
    const dateA = a[sortBy] ? new Date(a[sortBy]).getTime() : null;
    const dateB = b[sortBy] ? new Date(b[sortBy]).getTime() : null;

    // Cong viec khong co ngay hop le duoc xep cuoi.
    const validA = dateA !== null && Number.isFinite(dateA);
    const validB = dateB !== null && Number.isFinite(dateB);

    if (!validA && validB) return 1;
    if (validA && !validB) return -1;

    if (validA && validB) {
    comparison = dateA - dateB;
    }
    }

    if (comparison !== 0) {
    return sortOrder === "asc" ? comparison : -comparison;
    }

    // Neu gia tri bang nhau, uu tien cong viec moi tao.
    return (
    new Date(b.createdAt).getTime() -
    new Date(a.createdAt).getTime()
    );
    });


    // Tim quyen chia se cua tai khoan dang dang nhap
    // tren nhung cong viec duoc phep xem.
    const sharesForUser = await TaskShare.find({
      taskId: { $in: tasks.map((task) => task._id) },
      userId: userId
    }).select("taskId permission");

    const sharePermissions = new Map();

    for (const share of sharesForUser) {
      sharePermissions.set(
        String(share.taskId),
        share.permission
      );
    }

    // Xac dinh vai tro thuc te tren tung cong viec.
    const tasksWithRole = tasks.map((task) => {
      const taskData = task.toObject();

      const creatorId = task.createdBy?._id
        ? String(task.createdBy._id)
        : String(task.createdBy);

      const isOwner = creatorId === String(userId);

      const isAssignee = (task.assigneeIds || []).some(
        (person) => {
          const id = person?._id ?? person;
          return String(id) === String(userId);
        }
      );

      const sharePermission = sharePermissions.get(
        String(task._id)
      );

      let myRole = null;

      if (isOwner) {
        myRole = "owner";
      } else if (isAssignee) {
        myRole = "assignee";
      } else if (sharePermission === "editor") {
        myRole = "editor";
      } else if (sharePermission === "viewer") {
        myRole = "viewer";
      }

      return {
        ...taskData,
        myRole
      };
    });

    return res.status(200).json({
      success: true,
      count: tasksWithRole.length,
      data: tasksWithRole
    });

  } catch (error) {
    next(error);
  }
};


// POST /api/tasks
exports.createTask = async (req, res, next) => {
  try {
    const {
      title,
      description,
      startDate,
      dueDate,
      priority,
      status
    } = req.body;

    if (typeof title !== "string" || !title.trim()) {
      return res.status(400).json({
        success: false,
        message: "Tên công việc không được để trống"
      });
    }

    const task = await Task.create({
      title: title.trim(),
      description: description || "",
      startDate: startDate || null,
      dueDate: dueDate || null,
      priority: priority || "medium",
      status: status || "todo",
      createdBy: req.user.id,
      assigneeIds: []
    });

    res.status(201).json({
      success: true,
      message: "Tạo công việc thành công",
      data: task
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/tasks/:id
exports.getTaskById = async (req, res, next) => {
  try {
    const task = await Task.findById(req.task._id)
      .populate("createdBy", "fullName email")
      .populate("assigneeIds", "fullName email")
      .populate("primaryAssigneeId", "fullName email");

    res.json({
      success: true,
      data: task
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/tasks/:id
exports.updateTask = async (req, res, next) => {
  try {
    const allowed = [
      "title",
      "description",
      "startDate",
      "dueDate",
      "priority"
    ];

    const updates = {};

    for (const field of allowed) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }

    if (
      updates.title !== undefined &&
      (typeof updates.title !== "string" ||
        !updates.title.trim())
    ) {
      return res.status(400).json({
        success: false,
        message: "Tên công việc không hợp lệ"
      });
    }

    const task = await Task.findByIdAndUpdate(
      req.task._id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: "Cập nhật công việc thành công",
      data: task
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/tasks/:id/status
exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (
      !["todo", "in_progress", "completed"].includes(status)
    ) {
      return res.status(400).json({
        success: false,
        message: "Trạng thái không hợp lệ"
      });
    }

    const task = await Task.findByIdAndUpdate(
      req.task._id,
      { status },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: "Cập nhật trạng thái thành công",
      data: task
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/tasks/:id
exports.deleteTask = async (req, res, next) => {
  try {
    await TaskShare.deleteMany({
      taskId: req.task._id
    });

    await Task.findByIdAndDelete(req.task._id);

    res.json({
      success: true,
      message: "Xóa công việc thành công"
    });
  } catch (error) {
    next(error);
  }
};
