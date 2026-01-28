import mongoose from 'mongoose';

const postSchema = new mongoose.Schema(
  {
    // Basic Info
    type: {
      type: String,
      enum: ['lost', 'found'],
      required: [true, 'Post type is required'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [150, 'Title cannot exceed 150 characters'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: [
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
      ],
      index: true,
    },
    status: {
      type: String,
      enum: ['active', 'reunited', 'expired', 'closed'],
      default: 'active',
      index: true,
    },

    // User Reference
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // Images
    images: [
      {
        url: {
          type: String,
          required: true,
        },
        publicId: {
          type: String,
        },
        thumbnail: {
          type: String,
        },
        caption: {
          type: String,
          maxlength: 200,
        },
      },
    ],

    // Location
    location: {
      description: {
        type: String,
        maxlength: 200,
      },
      address: {
        type: String,
        maxlength: 300,
      },
      city: {
        type: String,
        maxlength: 100,
        index: true,
      },
      country: {
        type: String,
        maxlength: 100,
      },
      coordinates: {
        type: {
          type: String,
          enum: ['Point'],
          default: 'Point',
        },
        coordinates: {
          type: [Number], // [longitude, latitude]
          default: [0, 0],
        },
      },
    },

    // Date of Loss/Find
    date: {
      type: Date,
      default: Date.now,
    },
    dateRangeStart: {
      type: Date,
    },
    dateRangeEnd: {
      type: Date,
    },

    // Item Attributes (for matching)
    attributes: {
      color: {
        type: String,
        maxlength: 50,
      },
      brand: {
        type: String,
        maxlength: 100,
      },
      model: {
        type: String,
        maxlength: 100,
      },
      size: {
        type: String,
        maxlength: 50,
      },
      material: {
        type: String,
        maxlength: 100,
      },
      uniqueIdentifiers: {
        type: String,
        maxlength: 500,
      },
      additionalDetails: {
        type: Map,
        of: String,
      },
    },

    // Contact Info
    contact: {
      name: {
        type: String,
        maxlength: 100,
      },
      email: {
        type: String,
        maxlength: 100,
      },
      phone: {
        type: String,
        maxlength: 20,
      },
      preferredMethod: {
        type: String,
        enum: ['email', 'phone', 'app'],
        default: 'app',
      },
    },

    // Reward (for lost items)
    reward: {
      offered: {
        type: Boolean,
        default: false,
      },
      amount: {
        type: Number,
        min: 0,
      },
      currency: {
        type: String,
        default: 'USD',
        maxlength: 3,
      },
      description: {
        type: String,
        maxlength: 200,
      },
    },

    // AI Metadata
    aiMetadata: {
      extractedAt: {
        type: Date,
      },
      confidence: {
        type: Number,
        min: 0,
        max: 1,
      },
      embedding: {
        type: [Number], // Vector embedding for similarity search
        index: false, // Will use separate vector index
      },
      detectedObjects: [
        {
          label: String,
          confidence: Number,
          boundingBox: {
            x: Number,
            y: Number,
            width: Number,
            height: Number,
          },
        },
      ],
      extractedText: {
        type: String,
      },
      suggestedCategory: {
        type: String,
      },
      suggestedAttributes: {
        type: Map,
        of: String,
      },
    },

    // Matching
    matchScore: {
      type: Number,
      default: 0,
      index: true,
    },
    potentialMatches: [
      {
        postId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Post',
        },
        score: Number,
        status: {
          type: String,
          enum: ['pending', 'confirmed', 'rejected'],
          default: 'pending',
        },
        matchedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    // Engagement
    viewCount: {
      type: Number,
      default: 0,
    },
    bookmarkCount: {
      type: Number,
      default: 0,
    },

    // Moderation
    isReported: {
      type: Boolean,
      default: false,
    },
    reportCount: {
      type: Number,
      default: 0,
    },
    isFlagged: {
      type: Boolean,
      default: false,
    },
    flagReason: {
      type: String,
    },

    // Expiration
    expiresAt: {
      type: Date,
      default: function () {
        // Default expiration: 90 days from creation
        return new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);
      },
      index: true,
    },

    // Source (for imported posts)
    source: {
      platform: {
        type: String,
        enum: ['app', 'web', 'facebook', 'twitter', 'import'],
        default: 'app',
      },
      originalUrl: {
        type: String,
      },
      importedAt: {
        type: Date,
      },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Compound indexes for common queries
postSchema.index({ type: 1, status: 1, createdAt: -1 });
postSchema.index({ category: 1, status: 1, createdAt: -1 });
postSchema.index({ 'location.city': 1, status: 1, createdAt: -1 });
postSchema.index({ user: 1, status: 1, createdAt: -1 });
postSchema.index({ status: 1, expiresAt: 1 });

// Geospatial index for location-based queries
postSchema.index({ 'location.coordinates': '2dsphere' });

// Text index for search
postSchema.index({
  title: 'text',
  description: 'text',
  'attributes.brand': 'text',
  'attributes.model': 'text',
});

// Virtual for age
postSchema.virtual('age').get(function () {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60 * 24));
});

// Virtual for days until expiration
postSchema.virtual('daysUntilExpiration').get(function () {
  if (!this.expiresAt) return null;
  return Math.max(
    0,
    Math.floor((this.expiresAt - Date.now()) / (1000 * 60 * 60 * 24))
  );
});

// Pre-save middleware
postSchema.pre('save', function (next) {
  // Generate thumbnail URLs if not set
  if (this.images && this.images.length > 0) {
    this.images.forEach((image) => {
      if (!image.thumbnail && image.url) {
        // Auto-generate thumbnail URL for Cloudinary
        if (image.url.includes('cloudinary.com')) {
          image.thumbnail = image.url.replace(
            '/upload/',
            '/upload/c_fill,w_300,h_300/'
          );
        } else {
          image.thumbnail = image.url;
        }
      }
    });
  }

  next();
});

// Static method to find nearby posts
postSchema.statics.findNearby = function (
  longitude,
  latitude,
  maxDistance = 10000
) {
  return this.find({
    'location.coordinates': {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude],
        },
        $maxDistance: maxDistance, // meters
      },
    },
    status: 'active',
  });
};

// Static method to find potential matches
postSchema.statics.findPotentialMatches = async function (postId) {
  const post = await this.findById(postId);
  if (!post) return [];

  const oppositeType = post.type === 'lost' ? 'found' : 'lost';

  return this.find({
    _id: { $ne: postId },
    type: oppositeType,
    status: 'active',
    category: post.category,
  }).limit(50);
};

// Instance method to increment view count
postSchema.methods.incrementViews = function () {
  this.viewCount += 1;
  return this.save({ validateBeforeSave: false });
};

const Post = mongoose.model('Post', postSchema);

export default Post;
