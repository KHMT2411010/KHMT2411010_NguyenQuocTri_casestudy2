
const mongoose = require('mongoose');

async function connectDatabase() {
  try {
    const uri = process.env.MONGODB_URI;

    if (!uri) {
      throw new Error('Chua cau hinh MONGODB_URI trong file .env');
    }

    await mongoose.connect(uri);

    console.log('MongoDB Atlas connected successfully');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
  }
}

module.exports = connectDatabase;
