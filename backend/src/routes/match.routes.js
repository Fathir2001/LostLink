import express from 'express';
import Match from '../models/Match.model.js';
import { protect } from '../middleware/auth.middleware.js';
import { mongoIdValidation } from '../middleware/validation.middleware.js';

const router = express.Router();

/**
 * @route   GET /api/matches
 * @desc    Get matches for current user
 * @access  Private
 */
router.get('/', protect, async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;

    const query = {
      $or: [
        { lostPostUser: req.user._id },
        { foundPostUser: req.user._id },
      ],
    };

    if (status) {
      query.status = status;
    }

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const [matches, total] = await Promise.all([
      Match.find(query)
        .populate('lostPost', 'title images type category location')
        .populate('foundPost', 'title images type category location')
        .populate('lostPostUser', 'name avatarUrl')
        .populate('foundPostUser', 'name avatarUrl')
        .sort({ score: -1, createdAt: -1 })
        .skip(skip)
        .limit(limitNum),
      Match.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: {
        matches,
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
 * @route   GET /api/matches/:id
 * @desc    Get single match details
 * @access  Private
 */
router.get('/:id', protect, mongoIdValidation, async (req, res, next) => {
  try {
    const match = await Match.findById(req.params.id)
      .populate('lostPost')
      .populate('foundPost')
      .populate('lostPostUser', 'name avatarUrl email')
      .populate('foundPostUser', 'name avatarUrl email');

    if (!match) {
      return res.status(404).json({
        success: false,
        message: 'Match not found',
      });
    }

    // Check authorization
    const isParticipant =
      match.lostPostUser._id.toString() === req.user._id.toString() ||
      match.foundPostUser._id.toString() === req.user._id.toString();

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this match',
      });
    }

    // Mark as viewed
    await match.markAsViewed(req.user._id);

    res.json({
      success: true,
      data: {
        match,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/matches/:id/confirm
 * @desc    Confirm a match
 * @access  Private
 */
router.post('/:id/confirm', protect, mongoIdValidation, async (req, res, next) => {
  try {
    const match = await Match.findById(req.params.id);

    if (!match) {
      return res.status(404).json({
        success: false,
        message: 'Match not found',
      });
    }

    // Check authorization
    const isLostUser =
      match.lostPostUser.toString() === req.user._id.toString();
    const isFoundUser =
      match.foundPostUser.toString() === req.user._id.toString();

    if (!isLostUser && !isFoundUser) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to confirm this match',
      });
    }

    await match.confirm(req.user._id, req.body.notes);

    // Update user stats if fully confirmed
    if (match.status === 'confirmed') {
      req.user.stats.matchesCount += 1;
      await req.user.save();
    }

    res.json({
      success: true,
      message: 'Match confirmed',
      data: {
        match,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/matches/:id/reject
 * @desc    Reject a match
 * @access  Private
 */
router.post('/:id/reject', protect, mongoIdValidation, async (req, res, next) => {
  try {
    const match = await Match.findById(req.params.id);

    if (!match) {
      return res.status(404).json({
        success: false,
        message: 'Match not found',
      });
    }

    // Check authorization
    const isLostUser =
      match.lostPostUser.toString() === req.user._id.toString();
    const isFoundUser =
      match.foundPostUser.toString() === req.user._id.toString();

    if (!isLostUser && !isFoundUser) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject this match',
      });
    }

    await match.reject(req.user._id, req.body.notes);

    res.json({
      success: true,
      message: 'Match rejected',
      data: {
        match,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/matches/unread/count
 * @desc    Get count of unread matches
 * @access  Private
 */
router.get('/unread/count', protect, async (req, res, next) => {
  try {
    const count = await Match.countDocuments({
      $or: [
        { lostPostUser: req.user._id },
        { foundPostUser: req.user._id },
      ],
      status: 'pending',
      'viewedBy.user': { $ne: req.user._id },
    });

    res.json({
      success: true,
      data: {
        unreadCount: count,
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;
