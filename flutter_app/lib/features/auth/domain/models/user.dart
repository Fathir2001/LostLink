import 'package:equatable/equatable.dart';

/// User model
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? country;
  final String? city;
  final DateTime createdAt;
  final bool isVerified;
  final bool isAdmin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.country,
    this.city,
    required this.createdAt,
    this.isVerified = false,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      phone: json['phone'],
      country: json['country'],
      city: json['city'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'country': country,
      'city': city,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'isAdmin': isAdmin,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phone,
    String? country,
    String? city,
    DateTime? createdAt,
    bool? isVerified,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, phone, country, city, createdAt, isVerified, isAdmin];
}
