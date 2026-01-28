import fetch from 'node-fetch';
import Post from '../models/Post.model.js';
import Match from '../models/Match.model.js';

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

/**
 * Trigger AI matching for a new post
 * Runs in background, doesn't block post creation
 */
export const triggerMatchSearch = async (postId) => {
  try {
    console.log(`[Matching] Searching matches for post ${postId}`);

    const post = await Post.findById(postId);
    if (!post) {
      console.error(`[Matching] Post ${postId} not found`);
      return;
    }

    // Get potential matches from database
    const potentialMatches = await Post.findPotentialMatches(postId);

    if (potentialMatches.length === 0) {
      console.log(`[Matching] No potential matches found for post ${postId}`);
      return;
    }

    console.log(
      `[Matching] Found ${potentialMatches.length} potential matches`
    );

    // Generate embedding for the new post if not already done
    let postEmbedding = post.aiMetadata?.embedding;
    if (!postEmbedding || postEmbedding.length === 0) {
      postEmbedding = await generateEmbedding(post);
      if (postEmbedding) {
        post.aiMetadata = post.aiMetadata || {};
        post.aiMetadata.embedding = postEmbedding;
        await post.save();
      }
    }

    // Score each potential match
    const scoredMatches = [];

    for (const candidate of potentialMatches) {
      const score = await calculateMatchScore(post, candidate, postEmbedding);

      if (score.total >= 40) {
        // Only consider matches above threshold
        scoredMatches.push({
          post: candidate,
          score: score.total,
          breakdown: score.breakdown,
          reasons: score.reasons,
        });
      }
    }

    // Sort by score
    scoredMatches.sort((a, b) => b.score - a.score);

    // Take top matches
    const topMatches = scoredMatches.slice(0, 10);

    console.log(`[Matching] Found ${topMatches.length} quality matches`);

    // Create Match documents
    for (const match of topMatches) {
      await createMatch(post, match.post, match.score, match.breakdown, match.reasons);
    }

    console.log(`[Matching] Completed matching for post ${postId}`);
  } catch (error) {
    console.error(`[Matching] Error matching post ${postId}:`, error);
  }
};

/**
 * Generate embedding for a post using AI service
 */
async function generateEmbedding(post) {
  try {
    const text = `${post.title} ${post.description} ${post.attributes?.brand || ''} ${post.attributes?.model || ''} ${post.attributes?.color || ''}`;

    const response = await fetch(`${AI_SERVICE_URL}/embed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });

    if (!response.ok) {
      console.error('[AI] Embedding generation failed');
      return null;
    }

    const data = await response.json();
    return data.embedding;
  } catch (error) {
    console.error('[AI] Error generating embedding:', error.message);
    return null;
  }
}

/**
 * Calculate match score between two posts
 */
async function calculateMatchScore(post1, post2, post1Embedding = null) {
  const breakdown = {
    categoryMatch: 0,
    attributeMatch: 0,
    locationMatch: 0,
    timeMatch: 0,
    embeddingMatch: 0,
    textMatch: 0,
  };
  const reasons = [];

  // 1. Category Match (25 points max)
  if (post1.category === post2.category) {
    breakdown.categoryMatch = 25;
    reasons.push({
      factor: 'Category Match',
      score: 25,
      details: `Both items are in "${post1.category}" category`,
    });
  }

  // 2. Attribute Match (25 points max)
  let attrScore = 0;
  let attrDetails = [];

  if (
    post1.attributes?.color &&
    post2.attributes?.color &&
    post1.attributes.color.toLowerCase() === post2.attributes.color.toLowerCase()
  ) {
    attrScore += 8;
    attrDetails.push('color');
  }

  if (
    post1.attributes?.brand &&
    post2.attributes?.brand &&
    post1.attributes.brand.toLowerCase() === post2.attributes.brand.toLowerCase()
  ) {
    attrScore += 10;
    attrDetails.push('brand');
  }

  if (
    post1.attributes?.model &&
    post2.attributes?.model &&
    post1.attributes.model.toLowerCase() === post2.attributes.model.toLowerCase()
  ) {
    attrScore += 7;
    attrDetails.push('model');
  }

  breakdown.attributeMatch = Math.min(attrScore, 25);
  if (attrDetails.length > 0) {
    reasons.push({
      factor: 'Attribute Match',
      score: breakdown.attributeMatch,
      details: `Matching: ${attrDetails.join(', ')}`,
    });
  }

  // 3. Location Match (20 points max)
  if (post1.location?.city && post2.location?.city) {
    if (post1.location.city.toLowerCase() === post2.location.city.toLowerCase()) {
      breakdown.locationMatch = 20;
      reasons.push({
        factor: 'Location Match',
        score: 20,
        details: `Both items in ${post1.location.city}`,
      });
    } else if (
      post1.location?.coordinates?.coordinates &&
      post2.location?.coordinates?.coordinates
    ) {
      // Calculate distance
      const distance = calculateDistance(
        post1.location.coordinates.coordinates,
        post2.location.coordinates.coordinates
      );

      if (distance < 1) {
        breakdown.locationMatch = 20;
        reasons.push({
          factor: 'Location Match',
          score: 20,
          details: 'Items found within 1km of each other',
        });
      } else if (distance < 5) {
        breakdown.locationMatch = 15;
        reasons.push({
          factor: 'Location Match',
          score: 15,
          details: 'Items found within 5km of each other',
        });
      } else if (distance < 10) {
        breakdown.locationMatch = 10;
        reasons.push({
          factor: 'Location Match',
          score: 10,
          details: 'Items found within 10km of each other',
        });
      }
    }
  }

  // 4. Time Match (15 points max)
  const date1 = post1.date || post1.createdAt;
  const date2 = post2.date || post2.createdAt;
  const daysDiff = Math.abs(date1 - date2) / (1000 * 60 * 60 * 24);

  if (daysDiff <= 1) {
    breakdown.timeMatch = 15;
    reasons.push({
      factor: 'Time Match',
      score: 15,
      details: 'Items lost/found within 1 day of each other',
    });
  } else if (daysDiff <= 3) {
    breakdown.timeMatch = 12;
    reasons.push({
      factor: 'Time Match',
      score: 12,
      details: 'Items lost/found within 3 days of each other',
    });
  } else if (daysDiff <= 7) {
    breakdown.timeMatch = 8;
    reasons.push({
      factor: 'Time Match',
      score: 8,
      details: 'Items lost/found within a week of each other',
    });
  } else if (daysDiff <= 30) {
    breakdown.timeMatch = 4;
  }

  // 5. Embedding Similarity (15 points max) - if AI service available
  if (post1Embedding && post2.aiMetadata?.embedding) {
    const similarity = cosineSimilarity(post1Embedding, post2.aiMetadata.embedding);
    breakdown.embeddingMatch = Math.round(similarity * 15);

    if (similarity > 0.7) {
      reasons.push({
        factor: 'AI Similarity',
        score: breakdown.embeddingMatch,
        details: 'High semantic similarity detected',
      });
    }
  }

  // Calculate total
  const total = Object.values(breakdown).reduce((a, b) => a + b, 0);

  return {
    total: Math.min(total, 100),
    breakdown,
    reasons,
  };
}

/**
 * Create a Match document
 */
async function createMatch(post1, post2, score, breakdown, reasons) {
  try {
    // Determine which is lost and which is found
    const lostPost = post1.type === 'lost' ? post1 : post2;
    const foundPost = post1.type === 'found' ? post1 : post2;

    // Check if match already exists
    const existingMatch = await Match.findOne({
      lostPost: lostPost._id,
      foundPost: foundPost._id,
    });

    if (existingMatch) {
      // Update score if higher
      if (score > existingMatch.score) {
        existingMatch.score = score;
        existingMatch.scoreBreakdown = breakdown;
        existingMatch.matchReasons = reasons;
        await existingMatch.save();
      }
      return existingMatch;
    }

    // Create new match
    const match = await Match.create({
      lostPost: lostPost._id,
      foundPost: foundPost._id,
      lostPostUser: lostPost.user,
      foundPostUser: foundPost.user,
      score,
      scoreBreakdown: breakdown,
      matchReasons: reasons,
    });

    // Update potential matches on posts
    await Post.findByIdAndUpdate(lostPost._id, {
      $push: {
        potentialMatches: {
          postId: foundPost._id,
          score,
          status: 'pending',
        },
      },
    });

    await Post.findByIdAndUpdate(foundPost._id, {
      $push: {
        potentialMatches: {
          postId: lostPost._id,
          score,
          status: 'pending',
        },
      },
    });

    // TODO: Send push notifications to users

    console.log(
      `[Matching] Created match between ${lostPost._id} and ${foundPost._id} with score ${score}`
    );

    return match;
  } catch (error) {
    console.error('[Matching] Error creating match:', error);
    return null;
  }
}

/**
 * Calculate distance between two coordinates in km
 */
function calculateDistance(coord1, coord2) {
  const [lon1, lat1] = coord1;
  const [lon2, lat2] = coord2;

  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

function toRad(deg) {
  return deg * (Math.PI / 180);
}

/**
 * Calculate cosine similarity between two vectors
 */
function cosineSimilarity(vec1, vec2) {
  if (!vec1 || !vec2 || vec1.length !== vec2.length) {
    return 0;
  }

  let dotProduct = 0;
  let norm1 = 0;
  let norm2 = 0;

  for (let i = 0; i < vec1.length; i++) {
    dotProduct += vec1[i] * vec2[i];
    norm1 += vec1[i] * vec1[i];
    norm2 += vec2[i] * vec2[i];
  }

  const magnitude = Math.sqrt(norm1) * Math.sqrt(norm2);
  return magnitude > 0 ? dotProduct / magnitude : 0;
}

export default {
  triggerMatchSearch,
};
