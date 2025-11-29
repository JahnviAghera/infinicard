const bcrypt = require('bcryptjs');
const { query } = require('../config/database');
const { generateAccessToken, generateRefreshToken } = require('../middleware/auth');

// Register new user
const register = async (req, res) => {
  try {
    const { email, username, password, fullName } = req.body;

    // Check if user already exists
    const existingUser = await query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [email, username]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email or username already exists',
      });
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await query(
      `INSERT INTO users (email, username, password_hash, full_name, is_active)
       VALUES ($1, $2, $3, $4, TRUE)
       RETURNING id, email, username, full_name, created_at`,
      [email, username, passwordHash, fullName || null]
    );

    const user = result.rows[0];

    // Generate tokens
    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken(user.id);
    // Send welcome email asynchronously (do not block registration if mail fails)
    try {
      const { sendWelcomeEmail } = require('../mail');
      sendWelcomeEmail(user.email, user.full_name || user.username).catch(err => console.error('Welcome email error:', err));
    } catch (mailErr) {
      console.error('Failed to enqueue welcome email:', mailErr);
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          fullName: user.full_name,
          createdAt: user.created_at,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register user',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Request an OTP for an email (verification / password reset)
const requestOtp = async (req, res) => {
  try {
    const { email, purpose } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Missing `email` in body' });

    // generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await query(
      'INSERT INTO otps (email, code, purpose, expires_at) VALUES ($1, $2, $3, $4)',
      [email, otp, purpose || 'verification', expiresAt]
    );

    // send OTP email
    try {
      const { sendOtpEmail } = require('../mail');
      await sendOtpEmail(email, otp, purpose || 'verification');
    } catch (err) {
      console.error('Failed to send OTP email:', err);
    }

    res.json({ success: true, message: 'OTP generated and sent if possible' });
  } catch (error) {
    console.error('requestOtp error:', error);
    res.status(500).json({ success: false, message: 'Failed to request OTP' });
  }
};

// Verify OTP
const verifyOtp = async (req, res) => {
  try {
    const { email, otp, purpose } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: 'Missing `email` or `otp`' });

    const result = await query(
      `SELECT id, code, used, expires_at FROM otps WHERE email = $1 AND purpose = $2 ORDER BY created_at DESC LIMIT 1`,
      [email, purpose || 'verification']
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'OTP not found' });
    }

    const row = result.rows[0];
    if (row.used) return res.status(400).json({ success: false, message: 'OTP already used' });
    if (new Date(row.expires_at) < new Date()) return res.status(400).json({ success: false, message: 'OTP expired' });
    if (row.code !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });

    // mark used
    await query('UPDATE otps SET used = true WHERE id = $1', [row.id]);

    res.json({ success: true, message: 'OTP verified' });
  } catch (error) {
    console.error('verifyOtp error:', error);
    res.status(500).json({ success: false, message: 'Failed to verify OTP' });
  }
};

// Reset password using OTP (verify then update password)
const resetPasswordWithOtp = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) return res.status(400).json({ success: false, message: 'Missing fields' });

    // Verify OTP
    const verifyRes = await query(
      `SELECT id, code, used, expires_at FROM otps WHERE email = $1 AND purpose = $2 ORDER BY created_at DESC LIMIT 1`,
      [email, 'forgot-password']
    );
    if (verifyRes.rows.length === 0) return res.status(404).json({ success: false, message: 'OTP not found' });
    const row = verifyRes.rows[0];
    if (row.used) return res.status(400).json({ success: false, message: 'OTP already used' });
    if (new Date(row.expires_at) < new Date()) return res.status(400).json({ success: false, message: 'OTP expired' });
    if (row.code !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });

    // mark used
    await query('UPDATE otps SET used = true WHERE id = $1', [row.id]);

    // Update user's password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);
    const updateRes = await query('UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE email = $2 RETURNING id', [newPasswordHash, email]);
    if (updateRes.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('resetPasswordWithOtp error:', error);
    res.status(500).json({ success: false, message: 'Failed to reset password' });
  }
};

// Login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const result = await query(
      'SELECT id, email, username, password_hash, full_name, is_active FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = result.rows[0];

    // Check if account is active
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Account is inactive',
      });
    }

    // Verify password
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Update last login
    await query('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1', [user.id]);

    // Generate tokens
    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          fullName: user.full_name,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to login',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, email, username, full_name, created_at, last_login
       FROM users WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        fullName: user.full_name,
        createdAt: user.created_at,
        lastLogin: user.last_login,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Update user profile
const updateProfile = async (req, res) => {
  try {
    const { fullName } = req.body;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (fullName !== undefined) {
      updates.push(`full_name = $${paramCount}`);
      values.push(fullName);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update',
      });
    }

    values.push(req.user.id);

    const result = await query(
      `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramCount}
       RETURNING id, email, username, full_name, updated_at`,
      values
    );

    const user = result.rows[0];

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        fullName: user.full_name,
        updatedAt: user.updated_at,
      },
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Change password
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Get current password hash
    const result = await query(
      'SELECT password_hash FROM users WHERE id = $1',
      [req.user.id]
    );

    const user = result.rows[0];

    // Verify current password
    const passwordMatch = await bcrypt.compare(currentPassword, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Hash new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newPasswordHash, req.user.id]
    );

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
  requestOtp,
  verifyOtp,
  resetPasswordWithOtp,
};
