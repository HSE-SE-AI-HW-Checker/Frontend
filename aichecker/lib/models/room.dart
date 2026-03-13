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
    final rawScore = json['final_score'] ?? json['user_score'];
    return Room(
      id: json['room_id'] as String? ?? json['id'] as String,
      name: json['room_name'] as String? ?? json['name'] as String,
      participants: (json['participant_count'] ?? json['participants'] ?? 0) as int,
      submissions: (json['submissions_count'] ?? json['submissions']) as int?,
      userScore: rawScore is double ? rawScore.round() : rawScore as int?,
      lastActive: json['last_visit'] as String? ?? json['last_active'] as String?,
      deadline: json['deadline'] as String?,
      isActive: json['is_active'] as bool?,
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
