# 🔗 LostLink

> **AI-First Lost & Found Platform** — Reuniting people with their belongings through intelligent matching

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python)](https://python.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)](https://mongodb.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📖 Overview

LostLink is a modern Lost & Found platform that uses **AI as its core feature** to automatically match lost items with found items. The platform runs on a **$0 budget** using only free-tier services, and processes AI locally on a GPU for maximum privacy and cost efficiency.

### ✨ Key Features

- 🤖 **AI-Powered Matching** — Automatically matches lost/found items using embeddings, visual analysis, and semantic understanding
- 📸 **Smart Image Analysis** — Extracts item details, colors, text (OCR), and object detection from photos
- 🗺️ **Location-Aware** — Geospatial search with configurable radius matching
- 🔔 **Real-time Alerts** — Push notifications via Firebase when matches are found
- 🌐 **Cross-Platform** — One Flutter codebase for Android and Web
- 🔒 **Privacy-First** — All AI processing happens locally, no data sent to third parties
- 🎨 **Beautiful UI** — Material Design 3 with dark mode support and smooth animations

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        LostLink Platform                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ Flutter App  │◄──►│  Node.js API │◄──►│  AI Service  │       │
│  │  (Android)   │    │   (Express)  │    │  (FastAPI)   │       │
│  │    (Web)     │    │              │    │              │       │
│  └──────────────┘    └──────┬───────┘    └──────────────┘       │
│                             │                                    │
│                      ┌──────▼───────┐                           │
│                      │   MongoDB    │                           │
│                      │  (Atlas M0)  │                           │
│                      └──────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Mobile/Web** | Flutter 3.x | Cross-platform UI |
| **State Management** | Riverpod | Reactive state |
| **Navigation** | go_router | Declarative routing |
| **Backend** | Node.js + Express | REST API |
| **Database** | MongoDB Atlas (M0) | Document storage |
| **Image Storage** | Cloudinary (Free) | CDN + transformations |
| **AI Service** | Python + FastAPI | Local GPU processing |
| **Embeddings** | sentence-transformers | Semantic similarity |
| **Vision AI** | DETR + BLIP | Object detection + captioning |
| **OCR** | EasyOCR | Text extraction from images |
| **Push Notifications** | Firebase Cloud Messaging | Real-time alerts |
| **Maps** | OpenStreetMap + flutter_map | Location services |

---

## 📁 Project Structure

```
LostLink/
├── flutter_app/                 # Flutter mobile & web app
│   ├── lib/
│   │   ├── core/               # App-wide utilities
│   │   │   ├── config/         # Environment, routes, theme
│   │   │   ├── constants/      # App constants, colors
│   │   │   ├── network/        # API client, interceptors
│   │   │   └── utils/          # Helpers, extensions
│   │   ├── features/           # Feature modules
│   │   │   ├── auth/           # Authentication
│   │   │   ├── home/           # Main feed
│   │   │   ├── posts/          # Create/view posts
│   │   │   ├── search/         # Search & filters
│   │   │   ├── alerts/         # Notifications
│   │   │   ├── profile/        # User profile
│   │   │   ├── settings/       # App settings
│   │   │   ├── splash/         # Splash screen
│   │   │   └── onboarding/     # Onboarding flow
│   │   └── shared/             # Shared widgets
│   └── pubspec.yaml
│
├── backend/                     # Node.js REST API
│   ├── src/
│   │   ├── config/             # DB, Cloudinary config
│   │   ├── models/             # Mongoose schemas
│   │   ├── routes/             # Express routes
│   │   ├── middleware/         # Auth, validation, errors
│   │   ├── services/           # Business logic
│   │   └── server.js           # Entry point
│   ├── package.json
│   └── .env.example
│
├── ai_service/                  # Python AI microservice
│   ├── models/                 # AI model wrappers
│   │   ├── embedder.py         # Sentence embeddings
│   │   ├── vision.py           # Object detection + captioning
│   │   ├── ocr.py              # Text extraction
│   │   └── extractor.py        # Item attribute extraction
│   ├── utils/                  # Utilities
│   │   └── prompts.py          # AI prompts & categories
│   ├── main.py                 # FastAPI entry point
│   ├── requirements.txt
│   └── .env.example
│
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter** 3.10+ with Android SDK
- **Node.js** 20.x LTS
- **Python** 3.10+ with pip
- **MongoDB Atlas** account (free M0 tier)
- **Cloudinary** account (free tier)
- **Firebase** project (for FCM)
- **NVIDIA GPU** (optional, for faster AI)

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/yourusername/lostlink.git
cd lostlink
```

### 2️⃣ AI Service Setup

```bash
cd ai_service

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run the service
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### 3️⃣ Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your MongoDB URI, JWT secret, Cloudinary keys, etc.

# Run development server
npm run dev

# Run production server
npm start
```

### 4️⃣ Flutter App Setup

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Build Android APK
flutter build apk --release

# Build Web
flutter build web --release
```

---

## 🔧 Configuration

### Environment Variables

#### Backend (.env)

```env
# Server
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/lostlink

# JWT
JWT_SECRET=your-super-secret-key-change-this
JWT_EXPIRE=7d
JWT_REFRESH_EXPIRE=30d

# Cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# AI Service
AI_SERVICE_URL=http://localhost:8001

# Firebase (for push notifications)
FIREBASE_PROJECT_ID=your-project-id
```

#### AI Service (.env)

```env
# GPU Settings
CUDA_VISIBLE_DEVICES=0
USE_GPU=true

# Model Settings
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
DETECTION_MODEL=facebook/detr-resnet-50
CAPTION_MODEL=Salesforce/blip-image-captioning-base

# Rate Limits
MAX_CONCURRENT_REQUESTS=10
REQUEST_TIMEOUT=30
```

---

## 📡 API Reference

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Create new account |
| `POST` | `/api/auth/login` | Login with credentials |
| `POST` | `/api/auth/refresh` | Refresh access token |
| `POST` | `/api/auth/logout` | Logout user |
| `POST` | `/api/auth/forgot-password` | Request password reset |
| `POST` | `/api/auth/reset-password/:token` | Reset password |
| `GET` | `/api/auth/me` | Get current user |

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/posts` | Get all posts (paginated) |
| `GET` | `/api/posts/:id` | Get single post |
| `POST` | `/api/posts` | Create new post |
| `PUT` | `/api/posts/:id` | Update post |
| `DELETE` | `/api/posts/:id` | Delete post |
| `POST` | `/api/posts/:id/report` | Report post |
| `POST` | `/api/posts/:id/bookmark` | Toggle bookmark |
| `GET` | `/api/posts/nearby` | Get nearby posts |

### Matches

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/matches` | Get user's matches |
| `GET` | `/api/matches/unread` | Get unread count |
| `POST` | `/api/matches/:id/confirm` | Confirm match |
| `POST` | `/api/matches/:id/reject` | Reject match |

### Upload

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/upload/single` | Upload single image |
| `POST` | `/api/upload/multiple` | Upload multiple images |

### AI Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/extract/text` | Extract from text description |
| `POST` | `/extract/image` | Extract from image |
| `POST` | `/extract/combined` | Extract from text + images |
| `POST` | `/embed` | Generate text embedding |
| `POST` | `/generate/caption` | Generate image caption |

---

## 🤖 AI Matching Algorithm

The matching system uses a multi-factor scoring algorithm:

```
Final Score = Σ (weight × factor_score)

Factors:
├── Semantic Similarity (35%)    → Embedding cosine similarity
├── Category Match (25%)         → Same category = full points
├── Attribute Match (20%)        → Color, brand, model overlap
├── Location Proximity (15%)     → Distance-based decay
└── Time Relevance (5%)          → Recency bonus
```

### Matching Thresholds

| Score Range | Classification |
|-------------|---------------|
| 85%+ | **Strong Match** — Very likely the same item |
| 70-84% | **Good Match** — Probable match, verify details |
| 50-69% | **Possible Match** — Some similarities |
| <50% | **Weak Match** — Unlikely, but worth checking |

---

## 🛣️ Roadmap

### Phase 1: MVP ✅
- [x] Flutter app with all screens
- [x] Node.js REST API
- [x] AI service with embeddings
- [x] User authentication
- [x] Post CRUD operations
- [x] Basic matching

### Phase 2: Enhancement 🚧
- [ ] Real-time chat between users
- [ ] Push notifications for matches
- [ ] Advanced search filters
- [ ] Image similarity search
- [ ] Reward system

### Phase 3: Scale 📅
- [ ] Multi-language support
- [ ] iOS deployment
- [ ] PWA enhancements
- [ ] Admin dashboard
- [ ] Analytics integration

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) — Beautiful native apps
- [sentence-transformers](https://sbert.net) — State-of-the-art embeddings
- [Hugging Face](https://huggingface.co) — Open source AI models
- [MongoDB Atlas](https://mongodb.com) — Free cloud database
- [Cloudinary](https://cloudinary.com) — Free image hosting

---

<p align="center">
  Made with ❤️ for reuniting people with their belongings
</p>