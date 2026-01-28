# Development Guide

## Quick Start Checklist

### 1. Prerequisites

- [ ] Flutter SDK 3.10+ installed
- [ ] Node.js 20.x LTS installed
- [ ] Python 3.10+ installed
- [ ] Git configured
- [ ] VS Code with Flutter extension
- [ ] Android Studio (for Android SDK)

### 2. External Services Setup

#### MongoDB Atlas (Free M0 Cluster)

1. Go to [mongodb.com/cloud/atlas](https://mongodb.com/cloud/atlas)
2. Create free account
3. Create new cluster (M0 Free Tier)
4. Create database user with password
5. Whitelist IP address (0.0.0.0/0 for development)
6. Get connection string: `mongodb+srv://user:pass@cluster.mongodb.net/lostlink`

#### Cloudinary (Free Tier)

1. Go to [cloudinary.com](https://cloudinary.com)
2. Create free account
3. From Dashboard, get:
   - Cloud Name
   - API Key
   - API Secret

#### Firebase (Cloud Messaging)

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create new project
3. Add Android app with package name: `com.lostlink.app`
4. Download `google-services.json` → place in `flutter_app/android/app/`
5. Enable Cloud Messaging in project settings
6. Get Server Key for backend notifications

---

## Development Workflow

### Starting the Stack

```bash
# Terminal 1: AI Service
cd ai_service
.\venv\Scripts\activate  # Windows
uvicorn main:app --reload --port 8001

# Terminal 2: Backend
cd backend
npm run dev

# Terminal 3: Flutter
cd flutter_app
flutter run
```

### Running Tests

```bash
# Flutter tests
cd flutter_app
flutter test

# Backend tests
cd backend
npm test

# AI Service tests
cd ai_service
pytest
```

---

## Project Configuration

### Flutter Environment

Create `flutter_app/lib/core/config/env_config.dart`:

```dart
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emulator
  );
  
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
}
```

Run with custom config:
```bash
flutter run --dart-define=API_URL=https://api.lostlink.app/api
```

### Backend Environment

Copy `.env.example` to `.env` and fill in values:

```env
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key-min-32-chars
JWT_EXPIRE=7d
CLOUDINARY_CLOUD_NAME=xxx
CLOUDINARY_API_KEY=xxx
CLOUDINARY_API_SECRET=xxx
AI_SERVICE_URL=http://localhost:8001
```

### AI Service Environment

```env
CUDA_VISIBLE_DEVICES=0
USE_GPU=true
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

---

## Code Style Guidelines

### Flutter/Dart

- Use feature-based folder structure
- One widget per file
- Use Riverpod for state management
- Follow Effective Dart guidelines
- Run `dart format .` before committing

### Node.js

- Use async/await over callbacks
- Use ESM modules
- Error handling in try/catch blocks
- Use express-validator for validation
- Document APIs with JSDoc comments

### Python

- Follow PEP 8
- Use type hints
- Docstrings for all public functions
- Use Black for formatting
- Use Pydantic for data validation

---

## Git Workflow

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation

### Commit Messages

Follow Conventional Commits:

```
feat: add AI image analysis
fix: resolve login token refresh issue
docs: update API documentation
refactor: simplify matching algorithm
```

---

## Troubleshooting

### Flutter Issues

**Error: Null check operator used on null value**
- Check Riverpod provider initialization
- Verify async state handling

**Error: Network issues on Android emulator**
- Use `10.0.2.2` instead of `localhost`
- Check network security config

### Backend Issues

**MongoDB connection failed**
- Check IP whitelist in Atlas
- Verify connection string format
- Check network connectivity

**JWT Token errors**
- Verify JWT_SECRET is set
- Check token expiration
- Clear stored tokens on client

### AI Service Issues

**CUDA out of memory**
- Reduce batch size
- Use smaller models
- Set `USE_GPU=false` for CPU mode

**Model loading slow**
- Models are cached after first load
- Consider pre-loading on startup

---

## Deployment

### Flutter Web

```bash
flutter build web --release
# Deploy build/web to any static host
```

### Flutter Android

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Backend (Railway/Render)

1. Push to GitHub
2. Connect repo to Railway/Render
3. Set environment variables
4. Deploy automatically

### AI Service (GPU Cloud)

Options for free/cheap GPU:
- Google Colab (free, limited)
- Kaggle Notebooks (free, limited)
- Vast.ai (pay-per-use)
- Lambda Labs (pay-per-use)

---

## Performance Optimization

### Flutter

- Use `const` constructors
- Implement `ListView.builder` for long lists
- Cache network images
- Profile with DevTools

### Backend

- Index MongoDB fields used in queries
- Use projection to limit returned fields
- Implement caching (Redis optional)
- Compress responses with gzip

### AI Service

- Batch embeddings when possible
- Cache frequent requests
- Use FP16 for GPU inference
- Preload models on startup

---

## Security Checklist

- [ ] JWT secrets are strong and unique
- [ ] Passwords are hashed with bcrypt
- [ ] Rate limiting is enabled
- [ ] Input validation on all endpoints
- [ ] SQL/NoSQL injection prevention
- [ ] XSS prevention in frontend
- [ ] HTTPS in production
- [ ] Environment variables not committed
- [ ] Sensitive data not logged
