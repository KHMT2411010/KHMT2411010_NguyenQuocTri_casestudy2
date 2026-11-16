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
    const email = String(req.query.q || "")
      .trim()
      .toLowerCase();

    // Kiem tra email
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Email khong hop le",
      });
    }

    // Escape ky tu dac biet cua RegExp
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    // Tim email chinh xac, khong phan biet hoa thuong
    const user = await User.findOne({
      email: new RegExp(`^${escapedEmail}$`, "i"),
    })
      .select("_id fullName email")
      .lean();

    return res.status(200).json({
      success: true,
      data: user ? [user] : [],
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
