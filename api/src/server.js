
require("dotenv").config();

const mongoose = require("mongoose");
const app = require("./app");

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error("Thiếu MONGODB_URI trong .env");
    }

    if (!process.env.JWT_SECRET) {
      throw new Error("Thiếu JWT_SECRET trong .env");
    }

    await mongoose.connect(process.env.MONGODB_URI);

    console.log("Ket noi MongoDB thanh cong!");

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running at http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Khoi dong that bai:", error.message);
    process.exit(1);
  }
}

startServer();
