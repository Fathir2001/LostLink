import mongoose from 'mongoose';

const matchSchema = new mongoose.Schema(
  {
    // The lost post
    lostPost: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      required: true,
      index: true,
    },
    // The found post
    foundPost: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      required: true,
      index: true,
    },
    // Users involved
    lostPostUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    foundPostUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // Match details
    score: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
      index: true,
    },
    confidence: {
      type: String,
      enum: ['low', 'medium', 'high', 'very_high'],
      default: 'medium',
    },
    status: {
      type: String,
      enum: ['pending', 'viewed', 'confirmed', 'rejected', 'expired'],
      default: 'pending',
      index: true,
    },
    // Match reasons (why AI matched these)
    matchReasons: [
      {
        factor: {
          type: String,
          required: true,
        },
        score: {
          type: Number,
          min: 0,
          max: 100,
        },
        details: {
          type: String,
        },
      },
    ],
    // Breakdown of match score
    scoreBreakdown: {
      categoryMatch: {
        type: Number,
        default: 0,
      },
      attributeMatch: {
        type: Number,
        default: 0,
      },
      locationMatch: {
        type: Number,
        default: 0,
      },
      timeMatch: {
        type: Number,
        default: 0,
      },
      embeddingMatch: {
        type: Number,
        default: 0,
      },
      textMatch: {
        type: Number,
        default: 0,
      },
    },
    // User feedback
    lostUserResponse: {
      status: {
        type: String,
        enum: ['pending', 'confirmed', 'rejected'],
        default: 'pending',
      },
      respondedAt: Date,
      notes: String,
    },
    foundUserResponse: {
      status: {
        type: String,
        enum: ['pending', 'confirmed', 'rejected'],
        default: 'pending',
      },
      respondedAt: Date,
      notes: String,
    },
    // Reunion info (if confirmed)
    reunion: {
      confirmedAt: Date,
      method: {
        type: String,
        enum: ['in_person', 'shipped', 'other'],
      },
      notes: String,
    },
    // Notifications
    notificationsSent: {
      lostUser: {
        type: Boolean,
        default: false,
      },
      foundUser: {
        type: Boolean,
        default: false,
      },
    },
    // View tracking
    viewedBy: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        viewedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Compound indexes
matchSchema.index({ lostPost: 1, foundPost: 1 }, { unique: true });
matchSchema.index({ status: 1, score: -1 });
matchSchema.index({ lostPostUser: 1, status: 1, createdAt: -1 });
matchSchema.index({ foundPostUser: 1, status: 1, createdAt: -1 });

// Virtual for confidence level based on score
matchSchema.virtual('confidenceLevel').get(function () {
  if (this.score >= 90) return 'very_high';
  if (this.score >= 75) return 'high';
  if (this.score >= 50) return 'medium';
  return 'low';
});

// Pre-save: set confidence based on score
matchSchema.pre('save', function (next) {
  if (this.isModified('score')) {
    if (this.score >= 90) this.confidence = 'very_high';
    else if (this.score >= 75) this.confidence = 'high';
    else if (this.score >= 50) this.confidence = 'medium';
    else this.confidence = 'low';
  }
  next();
});

// Static method to get user's matches
matchSchema.statics.getUserMatches = async function (userId, status = null) {
  const query = {
    $or: [{ lostPostUser: userId }, { foundPostUser: userId }],
  };

  if (status) {
    query.status = status;
  }

  return this.find(query)
    .populate('lostPost', 'title images category')
    .populate('foundPost', 'title images category')
    .sort({ score: -1, createdAt: -1 });
};

// Instance method to mark as viewed
matchSchema.methods.markAsViewed = function (userId) {
  const alreadyViewed = this.viewedBy.some(
    (v) => v.user.toString() === userId.toString()
  );

  if (!alreadyViewed) {
    this.viewedBy.push({ user: userId });
    if (this.status === 'pending') {
      this.status = 'viewed';
    }
  }

  return this.save();
};

// Instance method to confirm match
matchSchema.methods.confirm = async function (userId, notes = '') {
  const isLostUser = this.lostPostUser.toString() === userId.toString();
  const isFoundUser = this.foundPostUser.toString() === userId.toString();

  if (isLostUser) {
    this.lostUserResponse = {
      status: 'confirmed',
      respondedAt: new Date(),
      notes,
    };
  } else if (isFoundUser) {
    this.foundUserResponse = {
      status: 'confirmed',
      respondedAt: new Date(),
      notes,
    };
  }

  // If both users confirmed, mark as fully confirmed
  if (
    this.lostUserResponse.status === 'confirmed' &&
    this.foundUserResponse.status === 'confirmed'
  ) {
    this.status = 'confirmed';
    this.reunion = {
      confirmedAt: new Date(),
    };
  }

  return this.save();
};

// Instance method to reject match
matchSchema.methods.reject = function (userId, notes = '') {
  const isLostUser = this.lostPostUser.toString() === userId.toString();
  const isFoundUser = this.foundPostUser.toString() === userId.toString();

  if (isLostUser) {
    this.lostUserResponse = {
      status: 'rejected',
      respondedAt: new Date(),
      notes,
    };
  } else if (isFoundUser) {
    this.foundUserResponse = {
      status: 'rejected',
      respondedAt: new Date(),
      notes,
    };
  }

  // If either user rejected, mark as rejected
  this.status = 'rejected';

  return this.save();
};

const Match = mongoose.model('Match', matchSchema);

export default Match;
