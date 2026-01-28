import 'package:equatable/equatable.dart';

/// Post type enum
enum PostType { lost, found }

/// Post status enum
enum PostStatus { active, resolved, expired, hidden }

/// Post model
class Post extends Equatable {
  final String id;
  final PostType type;
  final PostStatus status;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final PostLocation? location;
  final DateTime? lostFoundDate;
  final ItemAttributes? attributes;
  final ContactInfo? contactInfo;
  final String? reward;
  final List<String> tags;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final List<String> bookmarkedBy;
  final AIMetadata? aiMetadata;
  final List<PostMatch>? matches;

  const Post({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    this.location,
    this.lostFoundDate,
    this.attributes,
    this.contactInfo,
    this.reward,
    required this.tags,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.bookmarkedBy = const [],
    this.aiMetadata,
    this.matches,
  });

  bool get isLost => type == PostType.lost;
  bool get isFound => type == PostType.found;
  bool get hasReward => reward != null && reward!.isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  String? get thumbnailUrl => hasImages ? images.first : null;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? json['id'],
      type: (json['type']?.toString().toLowerCase() == 'found') ? PostType.found : PostType.lost,
      status: _parseStatus(json['status']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      images: List<String>.from(json['images'] ?? []),
      location: json['location'] != null
          ? PostLocation.fromJson(json['location'])
          : null,
      lostFoundDate: json['lostFoundDate'] != null
          ? DateTime.parse(json['lostFoundDate'])
          : null,
      attributes: json['attributes'] != null
          ? ItemAttributes.fromJson(json['attributes'])
          : null,
      contactInfo: json['contactInfo'] != null
          ? ContactInfo.fromJson(json['contactInfo'])
          : null,
      reward: json['reward'],
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'] ?? json['user']?['_id'] ?? '',
      userName: json['userName'] ?? json['user']?['name'] ?? 'Unknown',
      userAvatar: json['userAvatar'] ?? json['user']?['avatarUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      viewCount: json['viewCount'] ?? 0,
      bookmarkedBy: List<String>.from(json['bookmarkedBy'] ?? []),
      aiMetadata: json['aiMetadata'] != null
          ? AIMetadata.fromJson(json['aiMetadata'])
          : null,
      matches: json['matches'] != null
          ? (json['matches'] as List).map((m) => PostMatch.fromJson(m)).toList()
          : null,
    );
  }

  static PostStatus _parseStatus(String? status) {
    switch (status) {
      case 'resolved':
        return PostStatus.resolved;
      case 'expired':
        return PostStatus.expired;
      case 'hidden':
        return PostStatus.hidden;
      default:
        return PostStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == PostType.found ? 'FOUND' : 'LOST',
      'status': status.name,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'location': location?.toJson(),
      'lostFoundDate': lostFoundDate?.toIso8601String(),
      'attributes': attributes?.toJson(),
      'contactInfo': contactInfo?.toJson(),
      'reward': reward,
      'tags': tags,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewCount': viewCount,
      'bookmarkedBy': bookmarkedBy,
      'aiMetadata': aiMetadata?.toJson(),
    };
  }

  Post copyWith({
    String? id,
    PostType? type,
    PostStatus? status,
    String? title,
    String? description,
    String? category,
    List<String>? images,
    PostLocation? location,
    DateTime? lostFoundDate,
    ItemAttributes? attributes,
    ContactInfo? contactInfo,
    String? reward,
    List<String>? tags,
    String? userId,
    String? userName,
    String? userAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    List<String>? bookmarkedBy,
    AIMetadata? aiMetadata,
    List<PostMatch>? matches,
  }) {
    return Post(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      location: location ?? this.location,
      lostFoundDate: lostFoundDate ?? this.lostFoundDate,
      attributes: attributes ?? this.attributes,
      contactInfo: contactInfo ?? this.contactInfo,
      reward: reward ?? this.reward,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      matches: matches ?? this.matches,
    );
  }

  @override
  List<Object?> get props => [id, type, status, title, description, category, images, location, lostFoundDate, attributes, contactInfo, reward, tags, userId, createdAt, updatedAt];
}

/// Location data
class PostLocation extends Equatable {
  final String? country;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;

  const PostLocation({
    this.country,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
  });

  String get displayText {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  factory PostLocation.fromJson(Map<String, dynamic> json) {
    return PostLocation(
      country: json['country'],
      city: json['city'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [country, city, address, latitude, longitude];
}

/// Item attributes
class ItemAttributes extends Equatable {
  final String? brand;
  final String? model;
  final String? color;
  final String? size;
  final String? uniqueMarks;
  final Map<String, dynamic>? customFields;

  const ItemAttributes({
    this.brand,
    this.model,
    this.color,
    this.size,
    this.uniqueMarks,
    this.customFields,
  });

  factory ItemAttributes.fromJson(Map<String, dynamic> json) {
    return ItemAttributes(
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      size: json['size'],
      uniqueMarks: json['uniqueMarks'],
      customFields: json['customFields'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'color': color,
      'size': size,
      'uniqueMarks': uniqueMarks,
      'customFields': customFields,
    };
  }

  @override
  List<Object?> get props => [brand, model, color, size, uniqueMarks, customFields];
}

/// Contact information
class ContactInfo extends Equatable {
  final String? phone;
  final String? email;
  final String? socialHandle;
  final String? preferredMethod;

  const ContactInfo({
    this.phone,
    this.email,
    this.socialHandle,
    this.preferredMethod,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'],
      email: json['email'],
      socialHandle: json['socialHandle'],
      preferredMethod: json['preferredMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'socialHandle': socialHandle,
      'preferredMethod': preferredMethod,
    };
  }

  @override
  List<Object?> get props => [phone, email, socialHandle, preferredMethod];
}

/// AI extraction metadata
class AIMetadata extends Equatable {
  final bool isAIGenerated;
  final Map<String, double>? confidenceScores;
  final String? sourceType; // 'text', 'screenshot', 'image'
  final String? originalText;
  final List<double>? embeddings;
  final DateTime? processedAt;

  const AIMetadata({
    this.isAIGenerated = false,
    this.confidenceScores,
    this.sourceType,
    this.originalText,
    this.embeddings,
    this.processedAt,
  });

  factory AIMetadata.fromJson(Map<String, dynamic> json) {
    return AIMetadata(
      isAIGenerated: json['isAIGenerated'] ?? false,
      confidenceScores: json['confidenceScores'] != null
          ? Map<String, double>.from(json['confidenceScores'])
          : null,
      sourceType: json['sourceType'],
      originalText: json['originalText'],
      embeddings: json['embeddings'] != null
          ? List<double>.from(json['embeddings'])
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAIGenerated': isAIGenerated,
      'confidenceScores': confidenceScores,
      'sourceType': sourceType,
      'originalText': originalText,
      'embeddings': embeddings,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [isAIGenerated, confidenceScores, sourceType, originalText, embeddings, processedAt];
}

/// Post match result
class PostMatch extends Equatable {
  final String matchedPostId;
  final double score;
  final String? title;
  final String? thumbnailUrl;
  final PostType? type;
  final DateTime? createdAt;

  const PostMatch({
    required this.matchedPostId,
    required this.score,
    this.title,
    this.thumbnailUrl,
    this.type,
    this.createdAt,
  });

  factory PostMatch.fromJson(Map<String, dynamic> json) {
    return PostMatch(
      matchedPostId: json['matchedPostId'] ?? json['postId'],
      score: (json['score'] ?? 0).toDouble(),
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      type: json['type'] == 'FOUND' ? PostType.found : PostType.lost,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchedPostId': matchedPostId,
      'score': score,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'type': type?.name.toUpperCase(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [matchedPostId, score, title, thumbnailUrl, type, createdAt];
}
