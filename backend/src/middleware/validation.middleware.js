import { body, param, query, validationResult } from 'express-validator';

/**
 * Validation result handler
 */
export const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((err) => ({
        field: err.path,
        message: err.msg,
      })),
    });
  }
  next();
};

/**
 * Auth validation rules
 */
export const registerValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ max: 100 })
    .withMessage('Name cannot exceed 100 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  validate,
];

export const loginValidation = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
  validate,
];

/**
 * Post validation rules
 */
export const createPostValidation = [
  body('type')
    .notEmpty()
    .withMessage('Post type is required')
    .isIn(['lost', 'found'])
    .withMessage('Type must be "lost" or "found"'),
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 150 })
    .withMessage('Title cannot exceed 150 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 2000 })
    .withMessage('Description cannot exceed 2000 characters'),
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn([
      'electronics',
      'documents',
      'accessories',
      'clothing',
      'bags',
      'keys',
      'pets',
      'jewelry',
      'sports',
      'books',
      'toys',
      'medical',
      'instruments',
      'other',
    ])
    .withMessage('Invalid category'),
  body('location.description')
    .optional()
    .isLength({ max: 200 })
    .withMessage('Location description cannot exceed 200 characters'),
  body('location.coordinates.coordinates')
    .optional()
    .isArray({ min: 2, max: 2 })
    .withMessage('Coordinates must be [longitude, latitude]'),
  body('images')
    .optional()
    .isArray({ max: 5 })
    .withMessage('Maximum 5 images allowed'),
  body('reward.amount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Reward amount must be positive'),
  validate,
];

export const updatePostValidation = [
  param('id').isMongoId().withMessage('Invalid post ID'),
  body('title')
    .optional()
    .trim()
    .isLength({ max: 150 })
    .withMessage('Title cannot exceed 150 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Description cannot exceed 2000 characters'),
  body('status')
    .optional()
    .isIn(['active', 'reunited', 'closed'])
    .withMessage('Invalid status'),
  validate,
];

/**
 * Query validation
 */
export const getPostsValidation = [
  query('type')
    .optional()
    .isIn(['lost', 'found'])
    .withMessage('Type must be "lost" or "found"'),
  query('category')
    .optional()
    .isIn([
      'electronics',
      'documents',
      'accessories',
      'clothing',
      'bags',
      'keys',
      'pets',
      'jewelry',
      'sports',
      'books',
      'toys',
      'medical',
      'instruments',
      'other',
    ])
    .withMessage('Invalid category'),
  query('status')
    .optional()
    .isIn(['active', 'reunited', 'expired', 'closed'])
    .withMessage('Invalid status'),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50'),
  query('lat')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  query('lng')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  query('radius')
    .optional()
    .isInt({ min: 1, max: 100000 })
    .withMessage('Radius must be between 1 and 100000 meters'),
  validate,
];

/**
 * ID validation
 */
export const mongoIdValidation = [
  param('id').isMongoId().withMessage('Invalid ID'),
  validate,
];

/**
 * Report validation
 */
export const reportValidation = [
  param('id').isMongoId().withMessage('Invalid post ID'),
  body('reason')
    .notEmpty()
    .withMessage('Reason is required')
    .isIn([
      'spam',
      'inappropriate',
      'scam',
      'misleading',
      'duplicate',
      'harassment',
      'other',
    ])
    .withMessage('Invalid reason'),
  body('description')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Description cannot exceed 1000 characters'),
  validate,
];
