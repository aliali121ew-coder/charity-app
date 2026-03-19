import 'package:flutter/material.dart';

enum WorkCategory {
  all,
  food,
  financial,
  medical,
  educational,
  seasonal,
  events,
  general,
}

extension WorkCategoryExt on WorkCategory {
  String get labelAr {
    switch (this) {
      case WorkCategory.all:
        return 'الكل';
      case WorkCategory.food:
        return 'توزيع الطعام';
      case WorkCategory.financial:
        return 'مساعدات مالية';
      case WorkCategory.medical:
        return 'رعاية طبية';
      case WorkCategory.educational:
        return 'دعم تعليمي';
      case WorkCategory.seasonal:
        return 'أعمال موسمية';
      case WorkCategory.events:
        return 'فعاليات';
      case WorkCategory.general:
        return 'أعمال عامة';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkCategory.all:
        return Icons.apps_rounded;
      case WorkCategory.food:
        return Icons.restaurant_rounded;
      case WorkCategory.financial:
        return Icons.account_balance_wallet_rounded;
      case WorkCategory.medical:
        return Icons.medical_services_rounded;
      case WorkCategory.educational:
        return Icons.school_rounded;
      case WorkCategory.seasonal:
        return Icons.celebration_rounded;
      case WorkCategory.events:
        return Icons.event_rounded;
      case WorkCategory.general:
        return Icons.volunteer_activism_rounded;
    }
  }

  Color get color {
    switch (this) {
      case WorkCategory.all:
        return const Color(0xFF5B4FCF);
      case WorkCategory.food:
        return const Color(0xFF10B981);
      case WorkCategory.financial:
        return const Color(0xFF8B5CF6);
      case WorkCategory.medical:
        return const Color(0xFFEF4444);
      case WorkCategory.educational:
        return const Color(0xFF3B82F6);
      case WorkCategory.seasonal:
        return const Color(0xFFF59E0B);
      case WorkCategory.events:
        return const Color(0xFF14B8A6);
      case WorkCategory.general:
        return const Color(0xFF6366F1);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case WorkCategory.all:
        return [const Color(0xFF5B4FCF), const Color(0xFF3D33A8)];
      case WorkCategory.food:
        return [const Color(0xFF10B981), const Color(0xFF047857)];
      case WorkCategory.financial:
        return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
      case WorkCategory.medical:
        return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
      case WorkCategory.educational:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      case WorkCategory.seasonal:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case WorkCategory.events:
        return [const Color(0xFF14B8A6), const Color(0xFF0F766E)];
      case WorkCategory.general:
        return [const Color(0xFF6366F1), const Color(0xFF4338CA)];
    }
  }
}

// ── Comment Model ─────────────────────────────────────────────────────────────
class WorkComment {
  final String id;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime date;
  final int likeCount;
  bool isLiked;

  WorkComment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.date,
    this.likeCount = 0,
    this.isLiked = false,
  });

  WorkComment copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? text,
    DateTime? date,
    int? likeCount,
    bool? isLiked,
  }) {
    return WorkComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      text: text ?? this.text,
      date: date ?? this.date,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

// ── Work Post Model ───────────────────────────────────────────────────────────
class WorkPost {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final WorkCategory category;
  final DateTime date;
  final String location;
  final List<String> tags;
  final int viewCount;
  int likeCount;
  bool isLiked;
  bool isSaved;
  final int beneficiaryCount;
  final bool isFeatured;
  final String? videoUrl;
  final String authorName;
  final String authorRole;
  final int shareCount;
  final List<WorkComment> comments;
  final List<String>? imageUrls; // multiple images support

  WorkPost({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.date,
    required this.location,
    this.tags = const [],
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.beneficiaryCount = 0,
    this.isFeatured = false,
    this.videoUrl,
    this.authorName = 'مؤسسة النور الخيرية',
    this.authorRole = 'إدارة المؤسسة',
    this.shareCount = 0,
    this.comments = const [],
    this.imageUrls,
  });

  WorkPost copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    WorkCategory? category,
    DateTime? date,
    String? location,
    List<String>? tags,
    int? viewCount,
    int? likeCount,
    bool? isLiked,
    bool? isSaved,
    int? beneficiaryCount,
    bool? isFeatured,
    String? videoUrl,
    String? authorName,
    String? authorRole,
    int? shareCount,
    List<WorkComment>? comments,
    List<String>? imageUrls,
  }) {
    return WorkPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      date: date ?? this.date,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      beneficiaryCount: beneficiaryCount ?? this.beneficiaryCount,
      isFeatured: isFeatured ?? this.isFeatured,
      videoUrl: videoUrl ?? this.videoUrl,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      shareCount: shareCount ?? this.shareCount,
      comments: comments ?? this.comments,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
