
const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

// API kiểm tra server
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Task Manager API dang hoat dong!"
  });
});

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Server dang hoat dong!"
  });
});

// Dang ky cac route Buoi 2
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/tasks", require("./routes/taskRoutes"));

app.use(
  "/api/tasks/:id/assignees",
  require("./routes/assignmentRoutes")
);

app.use(
  "/api/tasks/:id/shares",
  require("./routes/taskShareRoutes")
);

// Xu ly API khong ton tai
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "API khong ton tai"
  });
});

// Xu ly loi
app.use((err, req, res, next) => {
  console.error(err);

  res.status(500).json({
    success: false,
    message: "Loi may chu"
  });
});

// BAT BUOC phai co dong nay
module.exports = app;
