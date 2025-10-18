const { body, param, query, validationResult } = require('express-validator');

// Validation error handler
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: errors.array(),
    });
  }
  next();
};

// Auth validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Invalid email address'),
  body('username')
    .isLength({ min: 3, max: 100 })
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username must be 3-100 characters and contain only letters, numbers, and underscores'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long'),
  body('fullName').optional().isLength({ max: 255 }).trim(),
  handleValidationErrors,
];

const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Invalid email address'),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidationErrors,
];

// Business card validation rules
const createCardValidation = [
  body('fullName')
    .notEmpty()
    .withMessage('Full name is required')
    .isLength({ max: 255 })
    .trim(),
  body('jobTitle').optional().isLength({ max: 255 }).trim(),
  body('companyName').optional().isLength({ max: 255 }).trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().isLength({ max: 50 }).trim(),
  body('website').optional().isURL().isLength({ max: 500 }),
  body('address').optional().trim(),
  body('notes').optional().trim(),
  body('color')
    .optional()
    .matches(/^#[0-9A-Fa-f]{6}$/)
    .withMessage('Color must be a valid hex color'),
  body('isFavorite').optional().isBoolean(),
  handleValidationErrors,
];

const updateCardValidation = [
  param('id').isUUID().withMessage('Invalid card ID'),
  body('fullName').optional().isLength({ max: 255 }).trim(),
  body('jobTitle').optional().isLength({ max: 255 }).trim(),
  body('companyName').optional().isLength({ max: 255 }).trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().isLength({ max: 50 }).trim(),
  body('website').optional().isURL().isLength({ max: 500 }),
  body('address').optional().trim(),
  body('notes').optional().trim(),
  body('color')
    .optional()
    .matches(/^#[0-9A-Fa-f]{6}$/)
    .withMessage('Color must be a valid hex color'),
  body('isFavorite').optional().isBoolean(),
  handleValidationErrors,
];

// Contact validation rules
const createContactValidation = [
  body('firstName')
    .notEmpty()
    .withMessage('First name is required')
    .isLength({ max: 255 })
    .trim(),
  body('lastName').optional().isLength({ max: 255 }).trim(),
  body('company').optional().isLength({ max: 255 }).trim(),
  body('jobTitle').optional().isLength({ max: 255 }).trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().isLength({ max: 50 }).trim(),
  body('mobile').optional().isLength({ max: 50 }).trim(),
  body('isFavorite').optional().isBoolean(),
  handleValidationErrors,
];

const updateContactValidation = [
  param('id').isUUID().withMessage('Invalid contact ID'),
  body('firstName').optional().isLength({ max: 255 }).trim(),
  body('lastName').optional().isLength({ max: 255 }).trim(),
  body('company').optional().isLength({ max: 255 }).trim(),
  body('jobTitle').optional().isLength({ max: 255 }).trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().isLength({ max: 50 }).trim(),
  body('mobile').optional().isLength({ max: 50 }).trim(),
  body('isFavorite').optional().isBoolean(),
  handleValidationErrors,
];

// Tag validation rules
const createTagValidation = [
  body('name')
    .notEmpty()
    .withMessage('Tag name is required')
    .isLength({ max: 100 })
    .trim(),
  body('color')
    .optional()
    .matches(/^#[0-9A-Fa-f]{6}$/)
    .withMessage('Color must be a valid hex color'),
  handleValidationErrors,
];

// Search validation
const searchValidation = [
  query('q').optional().isLength({ min: 1, max: 255 }).trim(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  handleValidationErrors,
];

// UUID param validation
const uuidParamValidation = [
  param('id').isUUID().withMessage('Invalid ID format'),
  handleValidationErrors,
];

module.exports = {
  registerValidation,
  loginValidation,
  createCardValidation,
  updateCardValidation,
  createContactValidation,
  updateContactValidation,
  createTagValidation,
  searchValidation,
  uuidParamValidation,
  handleValidationErrors,
};
