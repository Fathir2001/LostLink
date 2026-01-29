import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';
import '../../../../core/config/env_config.dart';
import 'package:dio/dio.dart';

/// AI extraction result from text or image
class AIExtractionResult {
  final String postType; // 'LOST' or 'FOUND'
  final String category;
  final String title;
  final String cleanDescription;
  final Map<String, dynamic>? itemAttributes;
  final Map<String, dynamic>? location;
  final String? dateTime;
  final Map<String, dynamic>? contactInfo;
  final String? reward;
  final List<String> tags;
  final Map<String, double> confidenceScores;
  final String? originalText;

  AIExtractionResult({
    required this.postType,
    required this.category,
    required this.title,
    required this.cleanDescription,
    this.itemAttributes,
    this.location,
    this.dateTime,
    this.contactInfo,
    this.reward,
    required this.tags,
    required this.confidenceScores,
    this.originalText,
  });

  factory AIExtractionResult.fromJson(Map<String, dynamic> json) {
    return AIExtractionResult(
      postType: json['post_type'] ?? 'LOST',
      category: json['category'] ?? 'other',
      title: json['title'] ?? '',
      cleanDescription: json['clean_description'] ?? json['description'] ?? '',
      itemAttributes: json['item_attributes'],
      location: json['location'],
      dateTime: json['date_time'],
      contactInfo: json['contact_info'],
      reward: json['reward'],
      tags: List<String>.from(json['tags'] ?? []),
      confidenceScores: json['confidence_scores'] != null
          ? Map<String, double>.from(
              json['confidence_scores'].map((k, v) => MapEntry(k, (v as num).toDouble())))
          : {},
      originalText: json['original_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_type': postType,
      'category': category,
      'title': title,
      'clean_description': cleanDescription,
      'item_attributes': itemAttributes,
      'location': location,
      'date_time': dateTime,
      'contact_info': contactInfo,
      'reward': reward,
      'tags': tags,
      'confidence_scores': confidenceScores,
      'original_text': originalText,
    };
  }
}

/// AI Service repository for extraction and matching
class AIRepository {
  final Ref _ref;
  late final Dio _aiDio;

  AIRepository(this._ref) {
    _aiDio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.aiServiceUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Extract structured data from text (social media post)
  Future<AIExtractionResult> extractFromText(String text) async {
    final response = await _aiDio.post(
      '/extract/text',
      data: {'text': text},
    );
    return AIExtractionResult.fromJson(response.data);
  }

  /// Extract structured data from image(s)
  Future<AIExtractionResult> extractFromImage(List<String> imagePaths) async {
    final formData = FormData();
    
    // Only use the first image for now (AI service expects single image)
    if (imagePaths.isNotEmpty) {
      final multipartFile = await _createMultipartFile(imagePaths[0], 'image');
      formData.files.add(MapEntry('image', multipartFile));
    }

    final response = await _aiDio.post(
      '/extract/image',
      data: formData,
    );
    return AIExtractionResult.fromJson(response.data);
  }

  /// Extract from both text and images
  Future<AIExtractionResult> extractFromTextAndImage(
    String text,
    List<String> imagePaths,
  ) async {
    final formData = FormData.fromMap({
      'text': text,
    });
    
    // Only use the first image for now (AI service expects single image)
    if (imagePaths.isNotEmpty) {
      final multipartFile = await _createMultipartFile(imagePaths[0], 'image');
      formData.files.add(MapEntry('image', multipartFile));
    }

    final response = await _aiDio.post(
      '/extract/combined',
      data: formData,
    );
    return AIExtractionResult.fromJson(response.data);
  }

  /// Helper method to create MultipartFile that works on both web and native
  Future<MultipartFile> _createMultipartFile(String path, String fieldName) async {
    if (kIsWeb) {
      // On web, the path is a blob URL from image_picker
      // We need to fetch the bytes from the blob URL
      final response = await http.get(Uri.parse(path));
      final bytes = response.bodyBytes;
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType('image', 'jpeg'),
      );
    } else {
      // On native platforms, use the file path directly
      return await MultipartFile.fromFile(path);
    }
  }

  /// Generate embeddings for text
  Future<List<double>> generateEmbeddings(String text) async {
    final response = await _aiDio.post(
      '/embed',
      data: {'text': text},
    );
    return List<double>.from(response.data['embeddings']);
  }

  /// Generate shareable caption
  Future<String> generateCaption({
    required String title,
    required String description,
    required String postType,
    String? location,
    String? dateTime,
    String? contact,
    String? platform,
    bool includeHashtags = true,
  }) async {
    final response = await _aiDio.post(
      '/generate/caption',
      data: {
        'title': title,
        'description': description,
        'post_type': postType,
        'location': location,
        'date_time': dateTime,
        'contact': contact,
        'platform': platform,
        'include_hashtags': includeHashtags,
      },
    );
    return response.data['caption'];
  }

  /// Check AI service health
  Future<bool> checkHealth() async {
    try {
      final response = await _aiDio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// AI repository provider
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository(ref);
});
