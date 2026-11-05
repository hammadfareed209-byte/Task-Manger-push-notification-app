class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final String repeatType; // 'none', 'daily', 'weekly', 'monthly'
  final int priority; // 0 = Low, 1 = Medium, 2 = High
  final int reminderBeforeMinutes; // 0, 10, 15, 30, 60
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.repeatType = 'none',
    this.priority = 1,
    this.reminderBeforeMinutes = 15,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? repeatType,
    int? priority,
    int? reminderBeforeMinutes,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
      priority: priority ?? this.priority,
      reminderBeforeMinutes: reminderBeforeMinutes ?? this.reminderBeforeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'repeat_type': repeatType,
      'priority': priority,
      'reminder_before_minutes': reminderBeforeMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      dueDate: DateTime.parse(map['due_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      repeatType: (map['repeat_type'] as String?) ?? 'none',
      priority: (map['priority'] as int?) ?? 1,
      reminderBeforeMinutes: (map['reminder_before_minutes'] as int?) ?? 15,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
    );
  }
}
