import 'package:flutter/material.dart';

@immutable
class AmanatCategory {
  const AmanatCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory AmanatCategory.fromJson(Map<String, dynamic> json) {
    return AmanatCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

@immutable
class AmanatCampaign {
  const AmanatCampaign({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.categoryName,
    required this.categorySlug,
    required this.description,
    required this.goal,
    required this.endsAt,
    required this.neededAmount,
    required this.collectedAmount,
    required this.voluntaryAmount,
    required this.safaAmount,
    required this.remainingAmount,
    required this.helpersCount,
    required this.coverImageUrl,
    required this.isFeatured,
    required this.donors,
  });

  final int id;
  final String title;
  final String shortTitle;
  final String categoryName;
  final String categorySlug;
  final String description;
  final String goal;
  final String endsAt;
  final int neededAmount;
  final int collectedAmount;
  final int voluntaryAmount;
  final int safaAmount;
  final int remainingAmount;
  final int helpersCount;
  final String coverImageUrl;
  final bool isFeatured;
  final List<AmanatDonation> donors;

  double get progress => neededAmount <= 0 ? 0 : collectedAmount / neededAmount;
  double get voluntaryProgress =>
      neededAmount <= 0 ? 0 : voluntaryAmount / neededAmount;
  double get safaProgress => neededAmount <= 0 ? 0 : safaAmount / neededAmount;
  double get remainingProgress =>
      neededAmount <= 0 ? 0 : remainingAmount / neededAmount;

  factory AmanatCampaign.fromJson(Map<String, dynamic> json) {
    final donations = json['latest_donations'];
    return AmanatCampaign(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      shortTitle: (json['short_title'] ?? json['title'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      categorySlug: (json['category_slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      goal: (json['goal'] ?? '').toString(),
      endsAt: _formatDate((json['ends_at'] ?? '').toString()),
      neededAmount: (json['needed_amount'] as num?)?.toInt() ?? 0,
      collectedAmount: (json['collected_amount'] as num?)?.toInt() ?? 0,
      voluntaryAmount: (json['voluntary_amount'] as num?)?.toInt() ?? 0,
      safaAmount: (json['safa_amount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toInt() ?? 0,
      helpersCount: (json['helpers_count'] as num?)?.toInt() ?? 0,
      coverImageUrl: (json['cover_image_url'] ?? '').toString(),
      isFeatured: json['is_featured'] == true,
      donors: donations is List
          ? donations
                .whereType<Map>()
                .map(
                  (e) => AmanatDonation.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

@immutable
class AmanatDonation {
  const AmanatDonation({
    required this.id,
    required this.donorLabel,
    required this.amount,
    required this.status,
  });

  final int id;
  final String donorLabel;
  final int amount;
  final String status;

  factory AmanatDonation.fromJson(Map<String, dynamic> json) {
    return AmanatDonation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      donorLabel: (json['donor_label'] ?? 'Анонимный пользователь').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
    );
  }
}

String _formatDate(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${parsed.day} ${months[parsed.month - 1]}';
}
