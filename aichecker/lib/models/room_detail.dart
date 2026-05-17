class RoomCriterion {
  final String criterionText;
  final bool isAiVerified;

  RoomCriterion({required this.criterionText, required this.isAiVerified});

  factory RoomCriterion.fromJson(Map<String, dynamic> json) {
    return RoomCriterion(
      criterionText: json['criterion_text'] as String,
      isAiVerified: json['is_ai_verified'] as bool? ?? false,
    );
  }
}

class RoomDetail {
  final String id;
  final String name;
  final String description;
  final List<RoomCriterion> criteria;
  final String? language;
  final String? createdAt;
  final int participantCount;
  final String? creatorName;
  final String? password;

  RoomDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    this.language,
    this.createdAt,
    required this.participantCount,
    this.creatorName,
    this.password,
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'] as List<dynamic>? ?? [];
    return RoomDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      criteria: rawCriteria
          .map((e) => RoomCriterion.fromJson(e as Map<String, dynamic>))
          .toList(),
      language: json['language'] as String?,
      createdAt: json['created_at'] as String?,
      participantCount: (json['participant_count'] ?? 0) as int,
      creatorName: json['creator_name'] as String?,
      password: json['password'] as String?,
    );
  }
}
