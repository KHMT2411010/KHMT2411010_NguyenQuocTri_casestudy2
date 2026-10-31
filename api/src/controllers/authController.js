
const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// Tạo JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );
};

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập đầy đủ thông tin"
      });
    }

    if (typeof password !== "string" || password.length < 8) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu phải có ít nhất 8 ký tự"
      });
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "Email đã tồn tại"
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await User.create({
      fullName: String(fullName).trim(),
      email: normalizedEmail,
      passwordHash
    });

    const token = generateToken(user._id.toString());

    return res.status(201).json({
      success: true,
      message: "Đăng ký thành công",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Email đã tồn tại"
      });
    }

    console.error(error);
    return res.status(500).json({
      success: false,
      message: "Lỗi máy chủ"
    });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (typeof email !== "string" ||
        typeof password !== "string") {
      return res.status(400).json({
        success: false,
        message: "Email hoặc mật khẩu không hợp lệ"
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase()
    }).select("+passwordHash");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không chính xác"
      });
    }

    const validPassword = await bcrypt.compare(
      password,
      user.passwordHash
    );

    if (!validPassword) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không chính xác"
      });
    }

    const token = generateToken(user._id.toString());

    return res.json({
      success: true,
      message: "Đăng nhập thành công",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "Lỗi máy chủ"
    });
  }
};

// GET /api/auth/me
exports.me = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy người dùng"
      });
    }

    return res.json({
      success: true,
      data: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "Lỗi máy chủ"
    });
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { fullName, email } = req.body;
    const updates = {};

    if (fullName !== undefined) {
      if (typeof fullName !== "string" ||
          !fullName.trim()) {
        return res.status(400).json({
          success: false,
          message: "Họ tên không hợp lệ"
        });
      }

      updates.fullName = fullName.trim();
    }

    if (email !== undefined) {
      if (typeof email !== "string" ||
          !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        return res.status(400).json({
          success: false,
          message: "Email không hợp lệ"
        });
      }

      updates.email = email.trim().toLowerCase();

      const existing = await User.findOne({
        email: updates.email,
        _id: { $ne: req.user.id }
      });

      if (existing) {
        return res.status(409).json({
          success: false,
          message: "Email đã được sử dụng"
        });
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: "Không có thông tin cần cập nhật"
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản"
      });
    }

    return res.json({
      success: true,
      message: "Cập nhật thông tin thành công",
      data: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Email đã được sử dụng"
      });
    }
    next(error);
  }
};

const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (
      typeof currentPassword !== "string" ||
      typeof newPassword !== "string" ||
      newPassword.length < 8
    ) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu mới phải có ít nhất 8 ký tự"
      });
    }

    const user = await User.findById(
      req.user.id
    ).select("+passwordHash");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản"
      });
    }

    const validPassword = await bcrypt.compare(
      currentPassword,
      user.passwordHash
    );

    if (!validPassword) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu hiện tại không chính xác"
      });
    }

    if (currentPassword === newPassword) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu mới phải khác mật khẩu cũ"
      });
    }

    user.passwordHash = await bcrypt.hash(
      newPassword,
      12
    );

    await user.save();

    return res.json({
      success: true,
      message: "Đổi mật khẩu thành công"
    });
  } catch (error) {
    next(error);
  }
};

exports.updateProfile = updateProfile;
exports.changePassword = changePassword;
