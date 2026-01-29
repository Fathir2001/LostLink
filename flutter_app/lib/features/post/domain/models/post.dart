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
    // Handle images - can be list of strings or list of objects with url
    List<String> parseImages(dynamic imagesJson) {
      if (imagesJson == null) return [];
      if (imagesJson is! List) return [];
      return imagesJson.map<String>((img) {
        if (img is String) return img;
        if (img is Map<String, dynamic>) return img['url']?.toString() ?? '';
        return '';
      }).where((url) => url.isNotEmpty).toList();
    }

    // Safe list parsing
    List<String> parseStringList(dynamic listJson) {
      if (listJson == null) return [];
      if (listJson is! List) return [];
      return listJson.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    final user = json['user'];
    String resolvedUserId = (json['userId'] ?? '').toString();
    String resolvedUserName = (json['userName'] ?? 'Unknown').toString();
    String? resolvedUserAvatar = json['userAvatar']?.toString();
    if (user is Map) {
      resolvedUserId = (user['_id'] ?? resolvedUserId).toString();
      resolvedUserName = (user['name'] ?? resolvedUserName).toString();
      resolvedUserAvatar = user['avatarUrl']?.toString() ?? resolvedUserAvatar;
    } else if (user != null && resolvedUserId.isEmpty) {
      resolvedUserId = user.toString();
    }

    return Post(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type']?.toString().toLowerCase() == 'found') ? PostType.found : PostType.lost,
      status: _parseStatus(json['status']?.toString()),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'other').toString(),
      images: parseImages(json['images']),
      location: json['location'] != null && json['location'] is Map
          ? PostLocation.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
      lostFoundDate: json['lostFoundDate'] != null || json['date'] != null
          ? _parseDateTime(json['lostFoundDate'] ?? json['date'])
          : null,
      attributes: json['attributes'] != null && json['attributes'] is Map
          ? ItemAttributes.fromJson(Map<String, dynamic>.from(json['attributes']))
          : null,
      contactInfo: json['contactInfo'] != null && json['contactInfo'] is Map
          ? ContactInfo.fromJson(Map<String, dynamic>.from(json['contactInfo']))
          : null,
      reward: _parseReward(json['reward']),
      tags: parseStringList(json['tags']),
      userId: resolvedUserId,
      userName: resolvedUserName,
      userAvatar: resolvedUserAvatar,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      viewCount: _parseInt(json['viewCount']),
      bookmarkedBy: parseStringList(json['bookmarkedBy']),
      aiMetadata: json['aiMetadata'] != null && json['aiMetadata'] is Map
          ? AIMetadata.fromJson(Map<String, dynamic>.from(json['aiMetadata']))
          : null,
      matches: json['matches'] != null && json['matches'] is List
          ? (json['matches'] as List).map((m) => PostMatch.fromJson(Map<String, dynamic>.from(m))).toList()
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
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

  static String? _parseReward(dynamic reward) {
    if (reward == null) return null;
    if (reward is String) return reward.isNotEmpty ? reward : null;
    if (reward is Map) {
      // Handle reward object from backend
      final description = reward['description']?.toString();
      final amount = reward['amount'];
      if (description != null && description.isNotEmpty) return description;
      if (amount != null) return '\$$amount';
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
    // Extract latitude/longitude from coordinates if present
    double? lat, lng;
    if (json['coordinates'] != null) {
      final coords = json['coordinates'];
      if (coords is Map && coords['coordinates'] is List) {
        final coordList = coords['coordinates'] as List;
        if (coordList.length >= 2) {
          lng = (coordList[0] as num?)?.toDouble();
          lat = (coordList[1] as num?)?.toDouble();
        }
      }
    }
    
    return PostLocation(
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString() ?? json['description']?.toString(),
      latitude: lat ?? json['latitude']?.toDouble(),
      longitude: lng ?? json['longitude']?.toDouble(),
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
      matchedPostId: (json['matchedPostId'] ?? json['postId'] ?? json['_id'] ?? '').toString(),
      score: (json['score'] ?? 0).toDouble(),
      title: json['title']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      type: json['type']?.toString().toUpperCase() == 'FOUND' ? PostType.found : PostType.lost,
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
