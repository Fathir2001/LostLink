# API Documentation

## Base URLs

| Environment | URL |
|------------|-----|
| Development | `http://localhost:3000/api` |
| Production | `https://api.lostlink.app/api` |
| AI Service | `http://localhost:8001` |

---

## Authentication

All protected endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <access_token>
```

---

## Endpoints

### Auth

#### POST /auth/register

Create a new user account.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "phone": "+1234567890"  // optional
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "_id": "65abc123def456",
      "name": "John Doe",
      "email": "john@example.com",
      "avatar": null,
      "createdAt": "2024-01-15T10:30:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

#### POST /auth/login

Authenticate user and receive tokens.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "_id": "65abc123def456",
      "name": "John Doe",
      "email": "john@example.com"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

#### POST /auth/refresh

Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### Posts

#### GET /posts

Get paginated list of posts.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | number | 1 | Page number |
| limit | number | 20 | Items per page |
| type | string | - | Filter: "lost" or "found" |
| category | string | - | Filter by category |
| status | string | "active" | Filter: "active", "resolved" |
| lat | number | - | Latitude for geo-search |
| lng | number | - | Longitude for geo-search |
| radius | number | 10 | Search radius in km |
| sort | string | "-createdAt" | Sort field |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "posts": [
      {
        "_id": "65abc123def456",
        "type": "lost",
        "title": "Lost iPhone 15 Pro",
        "description": "Black iPhone 15 Pro with blue case...",
        "category": "electronics",
        "images": [
          {
            "url": "https://res.cloudinary.com/...",
            "publicId": "lostlink/abc123"
          }
        ],
        "location": {
          "type": "Point",
          "coordinates": [-73.9857, 40.7484],
          "address": "350 5th Ave, New York, NY",
          "city": "New York"
        },
        "attributes": {
          "color": "black",
          "brand": "Apple",
          "model": "iPhone 15 Pro",
          "serialNumber": null
        },
        "dateOccurred": "2024-01-15T14:00:00.000Z",
        "reward": 100,
        "user": {
          "_id": "65abc123def456",
          "name": "John Doe",
          "avatar": "https://..."
        },
        "status": "active",
        "views": 156,
        "createdAt": "2024-01-15T15:30:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "pages": 8
    }
  }
}
```

---

#### POST /posts

Create a new post.

**Request (multipart/form-data):**
```json
{
  "type": "lost",
  "title": "Lost iPhone 15 Pro",
  "description": "Black iPhone 15 Pro with blue case, lost near Central Park...",
  "category": "electronics",
  "images": ["<file>", "<file>"],
  "location": {
    "coordinates": [-73.9857, 40.7484],
    "address": "350 5th Ave, New York, NY",
    "city": "New York"
  },
  "attributes": {
    "color": "black",
    "brand": "Apple",
    "model": "iPhone 15 Pro"
  },
  "dateOccurred": "2024-01-15T14:00:00.000Z",
  "reward": 100,
  "contactPreference": "in_app"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "post": { ... },
    "matchesFound": 3
  }
}
```

---

#### GET /posts/:id

Get single post by ID.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "post": { ... }
  }
}
```

---

#### PUT /posts/:id

Update a post (owner only).

**Request:**
```json
{
  "title": "Updated title",
  "status": "resolved"
}
```

---

#### DELETE /posts/:id

Delete a post (owner only).

---

### Matches

#### GET /matches

Get user's matches.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "matches": [
      {
        "_id": "65abc123def456",
        "lostPost": { ... },
        "foundPost": { ... },
        "score": 0.87,
        "scoreBreakdown": {
          "semantic": 0.92,
          "category": 1.0,
          "attributes": 0.75,
          "location": 0.85,
          "time": 0.70
        },
        "status": "pending",
        "explanation": "High confidence match based on...",
        "createdAt": "2024-01-15T16:00:00.000Z"
      }
    ]
  }
}
```

---

#### POST /matches/:id/confirm

Confirm a match.

**Response (200):**
```json
{
  "success": true,
  "message": "Match confirmed"
}
```

---

#### POST /matches/:id/reject

Reject a match.

**Request:**
```json
{
  "reason": "Different item"
}
```

---

### Upload

#### POST /upload/single

Upload single image.

**Request (multipart/form-data):**
- `image`: File (max 5MB, jpg/png/webp)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://res.cloudinary.com/...",
    "publicId": "lostlink/abc123"
  }
}
```

---

### AI Service Endpoints

#### POST /extract/text

Extract item attributes from text description.

**Request:**
```json
{
  "text": "I lost my black iPhone 15 Pro with a blue case near Central Park yesterday."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "category": "electronics",
    "title": "iPhone 15 Pro",
    "attributes": {
      "color": "black",
      "brand": "Apple",
      "model": "iPhone 15 Pro",
      "distinctive_features": ["blue case"]
    },
    "confidence": 0.92
  }
}
```

---

#### POST /extract/image

Extract item attributes from image.

**Request (multipart/form-data):**
- `image`: File

**Response:**
```json
{
  "success": true,
  "data": {
    "detected_objects": [
      {"label": "cell phone", "confidence": 0.95, "box": [10, 20, 200, 400]}
    ],
    "caption": "a black smartphone on a wooden table",
    "colors": ["black", "brown"],
    "ocr_text": "Apple iPhone",
    "extracted_identifiers": {
      "serial_numbers": [],
      "phone_numbers": []
    }
  }
}
```

---

#### POST /embed

Generate embedding for text.

**Request:**
```json
{
  "text": "Black iPhone 15 Pro with blue case lost near Central Park"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "embedding": [0.123, -0.456, ...],  // 384-dim vector
    "dimension": 384
  }
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "message": "Email is required" }
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid request data |
| UNAUTHORIZED | 401 | Missing or invalid token |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource already exists |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

## Rate Limits

| Endpoint Type | Limit |
|--------------|-------|
| Authentication | 5 requests/minute |
| General API | 100 requests/minute |
| File Upload | 10 requests/minute |
| AI Service | 30 requests/minute |

---

## Webhooks (Future)

For real-time updates, we plan to support webhooks for:
- New match notifications
- Post status changes
- User verification updates
