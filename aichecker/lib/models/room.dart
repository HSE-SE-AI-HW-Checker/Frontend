class Room {
  final String id;
  final String name;
  final int participants;
  final int? submissions;
  final int? userScore;
  final String? lastActive;
  final String? deadline;
  final bool? isActive;
  final String? created;
  final String? description;
  final List<String>? criteria;

  Room({
    required this.id,
    required this.name,
    required this.participants,
    this.submissions,
    this.userScore,
    this.lastActive,
    this.deadline,
    this.isActive,
    this.created,
    this.description,
    this.criteria,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      // API возвращает participant_count, моки могут использовать participants
      participants: (json['participant_count'] ?? json['participants'] ?? 0) as int,
      submissions: json['submissions'] as int?,
      userScore: json['user_score'] as int?,
      lastActive: json['last_active'] as String?,
      deadline: json['deadline'] as String?,
      isActive: json['is_active'] as bool?,
      // API возвращает created_at, моки могут использовать created
      created: json['created_at'] as String? ?? json['created'] as String?,
      description: json['description'] as String?,
      criteria: (json['criteria'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'submissions': submissions,
      'user_score': userScore,
      'last_active': lastActive,
      'deadline': deadline,
      'is_active': isActive,
      'created': created,
      'description': description,
      'criteria': criteria,
    };
  }
}
