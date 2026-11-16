const nodemailer = require("nodemailer");
const EmailLog = require("../models/EmailLog");

function createTransporter() {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS) {
    throw new Error("Chua cau hinh day du SMTP trong .env");
  }

  const port = Number(SMTP_PORT);

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("SMTP_PORT khong hop le");
  }

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port,
    secure: port === 465,
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS,
    },
  });
}

async function saveEmailLog(data) {
  try {
    await EmailLog.create(data);
    return true;
  } catch (error) {
    console.error("Email log saving failed:", error.message);
    return false;
  }
}

async function sendEmail({
  to,
  subject,
  text,
  taskId = null,
  userId = null,
  eventType = null,
}) {
  let result;

  try {
    const transporter = createTransporter();

    const sent = await transporter.sendMail({
      from: process.env.SMTP_USER,
      to,
      subject,
      text,
    });

    console.log("Email sent:", sent.messageId);

    result = {
      success: true,
      messageId: sent.messageId,
    };
  } catch (error) {
    console.error("Email sending failed:", error.message);

    result = {
      success: false,
      error: error.message,
    };
  }

  // Chi ghi log khi noi goi da cung cap loai su kien.
  // Cac controller cu van hoat dong nhu truoc.
  if (eventType) {
    const logged = await saveEmailLog({
      taskId,
      userId,
      recipientEmail: to,
      eventType,
      subject,
      status: result.success ? "sent" : "failed",
      messageId: result.messageId || "",
      errorMessage: result.error || "",
      sentAt: result.success ? new Date() : null,
    });

    if (!logged) {
      console.warn("D6: Email result was not persisted to EmailLog");
    }
  }

  return result;
}

module.exports = { sendEmail };
