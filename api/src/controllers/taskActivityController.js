const TaskActivity = require("../models/TaskActivity");

// Register User model for Mongoose populate().
require("../models/User");

// GET /api/tasks/:id/activities
// Route must require authentication and permissionMiddleware("view").
exports.getTaskActivities = async (req, res, next) => {
  try {
    const taskId = req.task._id;

    const activities = await TaskActivity.find({ taskId })
      .populate("userId", "fullName email")
      .sort({ createdAt: -1, _id: -1 })
      .limit(100)
      .lean();

    res.json({
      success: true,
      message: "Lay lich su hoat dong thanh cong",
      data: activities,
    });
  } catch (error) {
    next(error);
  }
};