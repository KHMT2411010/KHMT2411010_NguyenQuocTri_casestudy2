const express = require("express");
const cors = require("cors");

const User = require("./models/User");
const authMiddleware = require("./middleware/authMiddleware");

const app = express();

app.use(cors());
app.use(express.json());

// Kiem tra server
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Task Manager API dang hoat dong!",
  });
});

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Server dang hoat dong!",
  });
});

// API tai khoan
app.use("/api/auth", require("./routes/authRoutes"));

// API quan ly cong viec
app.use("/api/tasks", require("./routes/taskRoutes"));

// API giao viec
app.use("/api/tasks/:id/assignees", require("./routes/assignmentRoutes"));

// API chia se cong viec
app.use("/api/tasks/:id/shares", require("./routes/taskShareRoutes"));

// D7 - API thong bao trong ung dung
app.use("/api/notifications", require("./routes/notificationRoutes"));

// API tim nguoi dung bang email - yeu cau JWT
app.get("/api/users/search", authMiddleware, async (req, res) => {
  try {
    const keyword = String(req.query.q || "").trim();

    if (keyword.length < 2 || keyword.length > 100) {
      return res.status(400).json({
        success: false,
        message: "Nhap tu 2 den 100 ky tu de tim kiem",
      });
    }

    // Escape special RegExp characters before searching.
    const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const pattern = new RegExp(escaped, "i");

    const users = await User.find({
      $or: [
        { email: pattern },
        { fullName: pattern },
      ],
    })
      .select("_id fullName email")
      .sort({ fullName: 1, email: 1 })
      .limit(10)
      .lean();

    return res.status(200).json({
      success: true,
      data: users,
    });
  } catch (error) {
    console.error("Search user error:", error);

    return res.status(500).json({
      success: false,
      message: "Loi tim kiem nguoi dung",
    });
  }
});
// API khong ton tai
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "API khong ton tai",
  });
});

// Xu ly loi server
app.use((err, req, res, next) => {
  console.error(err);

  res.status(500).json({
    success: false,
    message: "Loi may chu",
  });
});

module.exports = app;
