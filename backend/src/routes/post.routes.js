import express from 'express';
import Post from '../models/Post.model.js';
import Report from '../models/Report.model.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';
import {
  createPostValidation,
  updatePostValidation,
  getPostsValidation,
  mongoIdValidation,
  reportValidation,
} from '../middleware/validation.middleware.js';
import { triggerMatchSearch } from '../services/matching.service.js';

const router = express.Router();

/**
 * @route   GET /api/posts
 * @desc    Get all posts with filters
 * @access  Public
 */
router.get('/', getPostsValidation, optionalAuth, async (req, res, next) => {
  try {
    const {
      type,
      category,
      status = 'active',
      keyword,
      city,
      lat,
      lng,
      radius = 10000,
      page = 1,
      limit = 20,
      sort = '-createdAt',
    } = req.query;

    // Build query
    const query = {};

    if (type) query.type = type;
    if (category) query.category = category;
    if (status) query.status = status;
    if (city) query['location.city'] = new RegExp(city, 'i');

    // Text search
    if (keyword) {
      query.$text = { $search: keyword };
    }

    // Location-based search
    if (lat && lng) {
      query['location.coordinates'] = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: parseInt(radius),
        },
      };
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Execute query
    const [posts, total] = await Promise.all([
      Post.find(query)
        .populate('user', 'name avatarUrl')
        .sort(sort)
        .skip(skip)
        .limit(limitNum)
        .lean(),
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
          hasMore: skip + posts.length < total,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/posts/:id
 * @desc    Get single post
 * @access  Public
 */
router.get('/:id', mongoIdValidation, optionalAuth, async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('user', 'name avatarUrl email')
      .populate('potentialMatches.postId', 'title images type');

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Increment view count (don't await)
    post.incrementViews();

    res.json({
      success: true,
      data: {
        post,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/posts
 * @desc    Create new post
 * @access  Private
 */
router.post('/', protect, createPostValidation, async (req, res, next) => {
  try {
    const postData = {
      ...req.body,
      user: req.user._id,
    };

    const post = await Post.create(postData);

    // Update user stats
    req.user.stats.postsCount += 1;
    await req.user.save();

    // Trigger AI matching in background
    triggerMatchSearch(post._id).catch(console.error);

    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: {
        post,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   PUT /api/posts/:id
 * @desc    Update post
 * @access  Private (owner only)
 */
router.put('/:id', protect, updatePostValidation, async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Check ownership
    if (post.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this post',
      });
    }

    // Update allowed fields
    const allowedUpdates = [
      'title',
      'description',
      'category',
      'status',
      'images',
      'location',
      'date',
      'attributes',
      'contact',
      'reward',
    ];

    allowedUpdates.forEach((field) => {
      if (req.body[field] !== undefined) {
        post[field] = req.body[field];
      }
    });

    // Handle status change
    if (req.body.status === 'reunited') {
      req.user.stats.reunionsCount += 1;
      await req.user.save();
    }

    await post.save();

    res.json({
      success: true,
      message: 'Post updated successfully',
      data: {
        post,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   DELETE /api/posts/:id
 * @desc    Delete post
 * @access  Private (owner only)
 */
router.delete('/:id', protect, mongoIdValidation, async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Check ownership
    if (
      post.user.toString() !== req.user._id.toString() &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this post',
      });
    }

    await post.deleteOne();

    // Update user stats
    if (req.user.stats.postsCount > 0) {
      req.user.stats.postsCount -= 1;
      await req.user.save();
    }

    res.json({
      success: true,
      message: 'Post deleted successfully',
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/posts/:id/report
 * @desc    Report a post
 * @access  Private
 */
router.post('/:id/report', protect, reportValidation, async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Check if already reported by this user
    const existingReport = await Report.findOne({
      reporter: req.user._id,
      targetType: 'post',
      targetId: post._id,
    });

    if (existingReport) {
      return res.status(400).json({
        success: false,
        message: 'You have already reported this post',
      });
    }

    // Create report
    await Report.create({
      reporter: req.user._id,
      targetType: 'post',
      targetId: post._id,
      reason: req.body.reason,
      description: req.body.description,
    });

    // Update post
    post.isReported = true;
    post.reportCount += 1;

    // Auto-flag if many reports
    if (post.reportCount >= 5) {
      post.isFlagged = true;
      post.flagReason = 'Multiple user reports';
    }

    await post.save();

    res.json({
      success: true,
      message: 'Post reported successfully. Our team will review it.',
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/posts/:id/bookmark
 * @desc    Toggle bookmark on a post
 * @access  Private
 */
router.post('/:id/bookmark', protect, mongoIdValidation, async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // For now, just increment/decrement bookmark count
    // In a full implementation, you'd store bookmarks in a separate collection
    // or user document
    const { action } = req.body; // 'add' or 'remove'

    if (action === 'add') {
      post.bookmarkCount += 1;
    } else if (action === 'remove' && post.bookmarkCount > 0) {
      post.bookmarkCount -= 1;
    }

    await post.save();

    res.json({
      success: true,
      message: action === 'add' ? 'Post bookmarked' : 'Bookmark removed',
      data: {
        bookmarkCount: post.bookmarkCount,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/posts/nearby/:lat/:lng
 * @desc    Get nearby posts
 * @access  Public
 */
router.get('/nearby/:lat/:lng', optionalAuth, async (req, res, next) => {
  try {
    const { lat, lng } = req.params;
    const { radius = 5000, limit = 20 } = req.query;

    const posts = await Post.findNearby(
      parseFloat(lng),
      parseFloat(lat),
      parseInt(radius)
    )
      .populate('user', 'name avatarUrl')
      .limit(parseInt(limit));

    res.json({
      success: true,
      data: {
        posts,
        count: posts.length,
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;
