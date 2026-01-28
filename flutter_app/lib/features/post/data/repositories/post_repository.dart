import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/services/api_client.dart';
import '../../domain/models/post.dart';

/// Search filters for posts
class PostFilters {
  final PostType? type;
  final String? category;
  final String? country;
  final String? city;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? keyword;
  final bool? hasImages;
  final bool? hasReward;
  final int page;
  final int limit;

  const PostFilters({
    this.type,
    this.category,
    this.country,
    this.city,
    this.dateFrom,
    this.dateTo,
    this.keyword,
    this.hasImages,
    this.hasReward,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (type != null) 'type': type == PostType.found ? 'FOUND' : 'LOST',
      if (category != null) 'category': category,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
      if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
      if (hasImages != null) 'hasImages': hasImages.toString(),
      if (hasReward != null) 'hasReward': hasReward.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }

  PostFilters copyWith({
    PostType? type,
    String? category,
    String? country,
    String? city,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? keyword,
    bool? hasImages,
    bool? hasReward,
    int? page,
    int? limit,
  }) {
    return PostFilters(
      type: type ?? this.type,
      category: category ?? this.category,
      country: country ?? this.country,
      city: city ?? this.city,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      keyword: keyword ?? this.keyword,
      hasImages: hasImages ?? this.hasImages,
      hasReward: hasReward ?? this.hasReward,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Paginated response
class PaginatedPosts {
  final List<Post> posts;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;

  const PaginatedPosts({
    required this.posts,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  factory PaginatedPosts.fromJson(Map<String, dynamic> json) {
    return PaginatedPosts(
      posts: (json['posts'] as List).map((p) => Post.fromJson(p)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Post repository for CRUD operations
class PostRepository {
  final Ref _ref;

  PostRepository(this._ref);

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  /// Get posts with filters
  Future<PaginatedPosts> getPosts(PostFilters filters) async {
    final response = await _apiClient.get(
      '/posts',
      queryParameters: filters.toQueryParams(),
    );
    return PaginatedPosts.fromJson(response.data);
  }

  /// Get single post by ID
  Future<Post> getPostById(String id) async {
    final response = await _apiClient.get('/posts/$id');
    return Post.fromJson(response.data['post']);
  }

  /// Create new post
  Future<Post> createPost(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/posts', data: data);
    return Post.fromJson(response.data['post']);
  }

  /// Update post
  Future<Post> updatePost(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/posts/$id', data: data);
    return Post.fromJson(response.data['post']);
  }

  /// Delete post
  Future<void> deletePost(String id) async {
    await _apiClient.delete('/posts/$id');
  }

  /// Upload images
  Future<List<String>> uploadImages(List<String> filePaths) async {
    final List<String> urls = [];
    for (final path in filePaths) {
      final response = await _apiClient.uploadFile('/upload/image', path);
      urls.add(response.data['url']);
    }
    return urls;
  }

  /// Bookmark post
  Future<void> bookmarkPost(String id) async {
    await _apiClient.post('/posts/$id/bookmark');
  }

  /// Remove bookmark
  Future<void> unbookmarkPost(String id) async {
    await _apiClient.delete('/posts/$id/bookmark');
  }

  /// Report post
  Future<void> reportPost(String id, String reason, String? details) async {
    await _apiClient.post('/posts/$id/report', data: {
      'reason': reason,
      'details': details,
    });
  }

  /// Get user's posts
  Future<List<Post>> getUserPosts(String userId) async {
    final response = await _apiClient.get('/users/$userId/posts');
    return (response.data['posts'] as List).map((p) => Post.fromJson(p)).toList();
  }

  /// Get bookmarked posts
  Future<List<Post>> getBookmarkedPosts() async {
    final response = await _apiClient.get('/posts/bookmarks');
    return (response.data['posts'] as List).map((p) => Post.fromJson(p)).toList();
  }

  /// Get matched posts
  Future<List<PostMatch>> getMatches(String postId) async {
    final response = await _apiClient.get('/posts/$postId/matches');
    return (response.data['matches'] as List)
        .map((m) => PostMatch.fromJson(m))
        .toList();
  }

  /// Mark post as resolved
  Future<Post> markAsResolved(String id) async {
    final response = await _apiClient.patch('/posts/$id/status', data: {
      'status': 'resolved',
    });
    return Post.fromJson(response.data['post']);
  }

  /// Generate shareable caption
  Future<String> generateCaption(String postId, {String? platform}) async {
    final response = await _apiClient.post('/posts/$postId/caption', data: {
      if (platform != null) 'platform': platform,
    });
    return response.data['caption'];
  }
}

/// Post repository provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref);
});
