const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const TaskReminder = require("../models/TaskReminder");
const User = require("../models/User");
const { sendEmail } = require("./emailService");
const { createNotification } = require("./notificationService");

const REMINDER_HOURS = 24;
const CHECK_INTERVAL_MS = 5 * 60 * 1000;
const MAX_ATTEMPTS = 3;
const SENDING_TIMEOUT_MS = 10 * 60 * 1000;

let timer = null;
let isRunning = false;

async function checkTaskReminders() {
  if (isRunning) return;

  isRunning = true;

  try {
    const now = new Date();

    const staleBefore = new Date(now.getTime() - SENDING_TIMEOUT_MS);

    // Khoi phuc cac lan gui bi gian doan qua 10 phut.
    // Chi thu lai neu chua vuot qua gioi han so lan gui.
    const recovery = await TaskReminder.updateMany(
      {
        status: "sending",
        updatedAt: { $lt: staleBefore },
        attempts: { $lt: MAX_ATTEMPTS },
      },
      {
        $set: {
          status: "failed",
          lastError: "Lan gui truoc bi gian doan",
        },
      },
    );

    if (recovery.modifiedCount > 0) {
      console.log(
        "D5 recovered interrupted reminders:",
        recovery.modifiedCount,
      );
    }

    const reminderWindowEnd = new Date(
      now.getTime() + REMINDER_HOURS * 60 * 60 * 1000,
    );

    // Tim cong viec chua hoan thanh va sap den han.
    const tasks = await Task.find({
      status: { $ne: "completed" },
      dueDate: {
        $gt: now,
        $lte: reminderWindowEnd,
      },
    });

    for (const task of tasks) {
      try {
        const shares = await TaskShare.find({
          taskId: task._id,
        }).select("userId");

        const recipientIds = new Set([
          String(task.createdBy),
          ...(task.assigneeIds || []).map(String),
          ...shares.map((share) => String(share.userId)),
        ]);

        const recipients = await User.find({
          _id: { $in: [...recipientIds] },
        }).select("fullName email");

        for (const user of recipients) {
          // Tao mot ban ghi nhac viec duy nhat.
          await TaskReminder.updateOne(
            {
              taskId: task._id,
              userId: user._id,
              dueDate: task.dueDate,
              reminderHours: REMINDER_HOURS,
            },
            {
              $setOnInsert: {
                status: "pending",
                attempts: 0,
              },
            },
            { upsert: true },
          );

          // Claim atomic de tranh hai luong gui cung mot reminder.
          const reminder = await TaskReminder.findOneAndUpdate(
            {
              taskId: task._id,
              userId: user._id,
              dueDate: task.dueDate,
              reminderHours: REMINDER_HOURS,
              status: { $in: ["pending", "failed"] },
              attempts: { $lt: MAX_ATTEMPTS },
            },
            {
              $set: {
                status: "sending",
                lastError: "",
              },
              $inc: { attempts: 1 },
            },
            { new: true },
          );

          if (!reminder) continue;

          const dueDateText = task.dueDate.toLocaleDateString("vi-VN", {
            timeZone: "Asia/Ho_Chi_Minh",
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
          });

          // D7: Tao thong bao nhac han mot lan cho moi reminderId.
          // Loi thong bao khong duoc lam gian doan email D5/D6.
          try {
            const notificationResult = await createNotification({
              userId: user._id,
              taskId: task._id,
              reminderId: reminder._id,
              type: "task_reminder",
              title: "Công việc sắp đến hạn",
              message:
                'Công việc "' +
                task.title +
                '" sắp đến hạn vào ngày ' +
                dueDateText +
                ". Vui lòng kiểm tra tiến độ.",
            });

            if (!notificationResult.success) {
              console.error(
                "D7 reminder notification failed:",
                String(reminder._id),
                notificationResult.error,
              );
            }
          } catch (notificationError) {
            console.error(
              "D7 reminder notification error:",
              String(reminder._id),
              notificationError.message,
            );
          }
          const result = await sendEmail({
            to: user.email,
            taskId: task._id,
            userId: user._id,
            eventType: "task_reminder",
            subject: "[TaskManager] Nhac viec truoc han 24 gio",
            text:
              "Xin chao " +
              user.fullName +
              ",\n\n" +
              "Cong viec sau sap den han hoan thanh:\n\n" +
              "Ten cong viec: " +
              task.title +
              "\n" +
              "Han hoan thanh: " +
              dueDateText +
              "\n" +
              "Muc do uu tien: " +
              task.priority +
              "\n\n" +
              "Vui long dang nhap TaskManager de kiem tra tien do.\n\n" +
              "TaskManager",
          });

          if (result.success) {
            reminder.status = "sent";
            reminder.sentAt = new Date();
            reminder.lastError = "";
          } else {
            reminder.status = "failed";
            reminder.lastError = String(result.error || "Gui email that bai");
          }

          await reminder.save();
        }
      } catch (taskError) {
        console.error(
          "D5 task reminder error:",
          String(task._id),
          taskError.message,
        );
      }
    }
  } catch (error) {
    console.error("D5 scheduler error:", error.message);
  } finally {
    isRunning = false;
  }
}

function startReminderScheduler() {
  if (timer) return;

  console.log("D5 reminder scheduler started: every 5 minutes");

  // Kiem tra ngay khi khoi dong Backend.
  void checkTaskReminders();

  timer = setInterval(() => {
    void checkTaskReminders();
  }, CHECK_INTERVAL_MS);
}

function stopReminderScheduler() {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

module.exports = {
  checkTaskReminders,
  startReminderScheduler,
  stopReminderScheduler,
};
