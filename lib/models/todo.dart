// lib/models/todo.dart
// Design Ref: §2.1 Model 클래스 설계

class Todo {
  const Todo({
    required this.id,
    required this.familyId,
    required this.createdBy,
    this.assignedTo,
    required this.text,
    this.category,
    required this.isDone,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String? assignedTo;
  final String text;
  final String? category; // '장보기' | '집안일' | '기타'
  final bool isDone;
  final DateTime? completedAt;
  final DateTime createdAt;

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        createdBy: json['created_by'] as String,
        assignedTo: json['assigned_to'] as String?,
        text: json['text'] as String,
        category: json['category'] as String?,
        isDone: json['is_done'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Todo copyWith({
    bool? isDone,
    DateTime? completedAt,
    String? text,
    String? category,
    String? assignedTo,
  }) =>
      Todo(
        id: id,
        familyId: familyId,
        createdBy: createdBy,
        assignedTo: assignedTo ?? this.assignedTo,
        text: text ?? this.text,
        category: category ?? this.category,
        isDone: isDone ?? this.isDone,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );
}
