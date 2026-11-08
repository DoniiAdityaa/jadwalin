/// Model jadwal untuk layer data (murni data, tanpa Flutter widget).
class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.description,
    this.categoryId,
    this.location,
    this.isAllDay = false,
    this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get durationMinutes => endAt.difference(startAt).inMinutes;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'location': location,
        'start_at': startAt.millisecondsSinceEpoch,
        'end_at': endAt.millisecondsSinceEpoch,
        'is_all_day': isAllDay ? 1 : 0,
        'reminder_min': reminderMinutes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ScheduleModel.fromMap(Map<String, Object?> map) => ScheduleModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        categoryId: map['category_id'] as String?,
        location: map['location'] as String?,
        startAt: DateTime.fromMillisecondsSinceEpoch(map['start_at'] as int),
        endAt: DateTime.fromMillisecondsSinceEpoch(map['end_at'] as int),
        isAllDay: (map['is_all_day'] as int? ?? 0) == 1,
        reminderMinutes: map['reminder_min'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );

  ScheduleModel copyWith({
    String? title,
    String? description,
    String? categoryId,
    String? location,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    int? reminderMinutes,
  }) {
    return ScheduleModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Model sesi percakapan chat.
class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ChatSessionModel.fromMap(Map<String, Object?> map) =>
      ChatSessionModel(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}

/// Model satu pesan chat.
class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  /// null saat belum disimpan ke DB.
  final int? id;
  final String sessionId;

  /// 'user' | 'assistant' | 'system'
  final String role;
  final String content;
  final DateTime createdAt;

  bool get isFromUser => role == 'user';

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessageModel.fromMap(Map<String, Object?> map) =>
      ChatMessageModel(
        id: map['id'] as int?,
        sessionId: map['session_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
