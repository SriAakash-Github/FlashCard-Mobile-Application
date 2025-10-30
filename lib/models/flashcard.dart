import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    String? id,
    required this.question,
    required this.answer,
    required this.categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy constructor for updates
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category_id': categoryId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map (database retrieval)
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      categoryId: map['category_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Validation methods
  bool isValid() {
    return question.trim().isNotEmpty && 
           answer.trim().isNotEmpty && 
           categoryId.trim().isNotEmpty;
  }

  String? validateQuestion() {
    if (question.trim().isEmpty) {
      return 'Question cannot be empty';
    }
    if (question.trim().length > 500) {
      return 'Question must be less than 500 characters';
    }
    return null;
  }

  String? validateAnswer() {
    if (answer.trim().isEmpty) {
      return 'Answer cannot be empty';
    }
    if (answer.trim().length > 1000) {
      return 'Answer must be less than 1000 characters';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Flashcard(id: $id, question: $question, answer: $answer, categoryId: $categoryId)';
  }
}