import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import connectDB from './config/database.js';
import authRoutes from './routes/auth.routes.js';
import postRoutes from './routes/post.routes.js';
import uploadRoutes from './routes/upload.routes.js';
import matchRoutes from './routes/match.routes.js';
import userRoutes from './routes/user.routes.js';
import { errorHandler, notFound } from './middleware/error.middleware.js';

// Load environment variables
dotenv.config();

// Create Express app
const app = express();

// Connect to MongoDB
connectDB();

// Security middleware
app.use(helmet());

// CORS
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Too many requests, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', limiter);

// Request logging
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'LostLink API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/posts', postRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/matches', matchRoutes);
app.use('/api/v1/users', userRoutes);

// API Documentation endpoint
app.get('/api/v1', (req, res) => {
  res.json({
    success: true,
    message: 'LostLink API v1',
    endpoints: {
      auth: {
        'POST /api/v1/auth/register': 'Register new user',
        'POST /api/v1/auth/login': 'Login user',
        'POST /api/v1/auth/refresh': 'Refresh access token',
        'POST /api/v1/auth/forgot-password': 'Request password reset',
        'POST /api/v1/auth/reset-password': 'Reset password with token',
        'GET /api/v1/auth/me': 'Get current user profile',
      },
      posts: {
        'GET /api/v1/posts': 'Get all posts with filters',
        'GET /api/v1/posts/:id': 'Get single post',
        'POST /api/v1/posts': 'Create new post',
        'PUT /api/v1/posts/:id': 'Update post',
        'DELETE /api/v1/posts/:id': 'Delete post',
        'POST /api/v1/posts/:id/report': 'Report a post',
        'POST /api/v1/posts/:id/bookmark': 'Bookmark a post',
      },
      matches: {
        'GET /api/v1/matches': 'Get matches for user posts',
        'GET /api/matches/:id': 'Get single match details',
        'POST /api/matches/:id/confirm': 'Confirm a match',
        'POST /api/matches/:id/reject': 'Reject a match',
      },
      upload: {
        'POST /api/upload/image': 'Upload single image',
        'POST /api/upload/images': 'Upload multiple images',
      },
      users: {
        'GET /api/users/:id': 'Get user profile',
        'PUT /api/users/profile': 'Update own profile',
        'GET /api/users/posts': 'Get user\'s posts',
      },
    },
  });
});

// 404 handler
app.use(notFound);

// Error handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🔗 LostLink API Server                                  ║
║                                                           ║
║   Environment: ${process.env.NODE_ENV || 'development'}                              ║
║   Port: ${PORT}                                              ║
║   URL: http://localhost:${PORT}                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

export default app;
