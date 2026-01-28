import express from 'express';
import User from '../models/User.model.js';
import Post from '../models/Post.model.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';
import { mongoIdValidation } from '../middleware/validation.middleware.js';

const router = express.Router();

/**
 * @route   GET /api/users/:id
 * @desc    Get user public profile
 * @access  Public
 */
router.get('/:id', mongoIdValidation, optionalAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id).select(
      'name avatarUrl bio stats createdAt settings.showProfile'
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if profile is public
    if (!user.settings?.showProfile) {
      return res.status(403).json({
        success: false,
        message: 'This profile is private',
      });
    }

    // Get user's public posts
    const posts = await Post.find({
      user: user._id,
      status: 'active',
    })
      .select('title type category images location createdAt')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          bio: user.bio,
          stats: user.stats,
          memberSince: user.createdAt,
        },
        recentPosts: posts,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   PUT /api/users/profile
 * @desc    Update current user's profile
 * @access  Private
 */
router.put('/profile', protect, async (req, res, next) => {
  try {
    const allowedFields = ['name', 'phone', 'bio'];
    const updates = {};

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    // Update settings if provided
    if (req.body.settings) {
      const allowedSettings = [
        'pushNotifications',
        'emailNotifications',
        'matchAlerts',
        'showProfile',
        'showPhone',
      ];

      allowedSettings.forEach((setting) => {
        if (req.body.settings[setting] !== undefined) {
          updates[`settings.${setting}`] = req.body.settings[setting];
        }
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: user.toJSON(),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/users/posts
 * @desc    Get current user's posts
 * @access  Private
 */
router.get('/me/posts', protect, async (req, res, next) => {
  try {
    const { status, type, page = 1, limit = 20 } = req.query;

    const query = { user: req.user._id };
    if (status) query.status = status;
    if (type) query.type = type;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const [posts, total] = await Promise.all([
      Post.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum),
      Post.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: {
        posts,
        pagination: {
          total,
          page: pageNum,
          limit: limitNum,
          pages: Math.ceil(total / limitNum),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   PUT /api/users/password
 * @desc    Change password
 * @access  Private
 */
router.put('/password', protect, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters',
      });
    }

    // Get user with password
    const user = await User.findById(req.user._id).select('+password');

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    user.refreshToken = undefined; // Invalidate all sessions
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   DELETE /api/users/account
 * @desc    Delete account
 * @access  Private
 */
router.delete('/account', protect, async (req, res, next) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required to delete account',
      });
    }

    // Get user with password
    const user = await User.findById(req.user._id).select('+password');

    // Verify password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Password is incorrect',
      });
    }

    // Delete user's posts
    await Post.deleteMany({ user: user._id });

    // Delete user
    await user.deleteOne();

    res.json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    next(error);
  }
});

export default router;
