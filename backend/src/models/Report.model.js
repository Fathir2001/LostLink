import mongoose from 'mongoose';

const reportSchema = new mongoose.Schema(
  {
    // Who is reporting
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // What is being reported
    targetType: {
      type: String,
      enum: ['post', 'user', 'match'],
      required: true,
    },
    targetId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    // Report details
    reason: {
      type: String,
      enum: [
        'spam',
        'inappropriate',
        'scam',
        'misleading',
        'duplicate',
        'harassment',
        'other',
      ],
      required: true,
    },
    description: {
      type: String,
      maxlength: 1000,
    },
    // Status
    status: {
      type: String,
      enum: ['pending', 'reviewing', 'resolved', 'dismissed'],
      default: 'pending',
      index: true,
    },
    // Resolution
    resolution: {
      action: {
        type: String,
        enum: ['none', 'warning', 'removed', 'banned'],
      },
      notes: String,
      resolvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
      resolvedAt: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to prevent duplicate reports
reportSchema.index(
  { reporter: 1, targetType: 1, targetId: 1 },
  { unique: true }
);

const Report = mongoose.model('Report', reportSchema);

export default Report;
