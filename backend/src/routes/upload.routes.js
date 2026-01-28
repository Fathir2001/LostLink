import express from 'express';
import multer from 'multer';
import { uploadImageBuffer } from '../config/cloudinary.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// Configure multer for memory storage
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 5,
  },
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

/**
 * @route   POST /api/upload/image
 * @desc    Upload single image
 * @access  Private
 */
router.post('/image', protect, upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided',
      });
    }

    const result = await uploadImageBuffer(req.file.buffer, 'lostlink/posts');

    res.json({
      success: true,
      message: 'Image uploaded successfully',
      data: {
        url: result.url,
        publicId: result.publicId,
        width: result.width,
        height: result.height,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/upload/images
 * @desc    Upload multiple images
 * @access  Private
 */
router.post(
  '/images',
  protect,
  upload.array('images', 5),
  async (req, res, next) => {
    try {
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No image files provided',
        });
      }

      const uploadPromises = req.files.map((file) =>
        uploadImageBuffer(file.buffer, 'lostlink/posts')
      );

      const results = await Promise.all(uploadPromises);

      res.json({
        success: true,
        message: `${results.length} images uploaded successfully`,
        data: {
          images: results.map((r) => ({
            url: r.url,
            publicId: r.publicId,
            width: r.width,
            height: r.height,
          })),
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   POST /api/upload/avatar
 * @desc    Upload user avatar
 * @access  Private
 */
router.post(
  '/avatar',
  protect,
  upload.single('avatar'),
  async (req, res, next) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided',
        });
      }

      const result = await uploadImageBuffer(req.file.buffer, 'lostlink/avatars');

      // Update user avatar
      req.user.avatarUrl = result.url;
      req.user.avatarPublicId = result.publicId;
      await req.user.save();

      res.json({
        success: true,
        message: 'Avatar uploaded successfully',
        data: {
          avatarUrl: result.url,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
