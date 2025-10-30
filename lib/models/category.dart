import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    String? color,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? '2196f3', // Blue color hex
        createdAt = createdAt ?? DateTime.now();

  // Copy constructor for updates
  Category copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map (database retrieval)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  // Get Color object from hex string
  Color get colorValue {
    try {
      return Color(int.parse(color, radix: 16));
    } catch (e) {
      return Colors.blue; // Default fallback color
    }
  }

  // Validation methods
  bool isValid() {
    return name.trim().isNotEmpty;
  }

  String? validateName() {
    if (name.trim().isEmpty) {
      return 'Category name cannot be empty';
    }
    if (name.trim().length > 50) {
      return 'Category name must be less than 50 characters';
    }
    return null;
  }

  // Predefined category colors
  static List<Color> get predefinedColors => [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  // Create category with predefined color
  factory Category.withPredefinedColor({
    String? id,
    required String name,
    required Color color,
    DateTime? createdAt,
  }) {
    return Category(
      id: id,
      name: name,
      color: _colorToHex(color),
      createdAt: createdAt,
    );
  }

  // Helper method to convert Color to hex string
  static String _colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '${r.toRadixString(16).padLeft(2, '0')}'
           '${g.toRadixString(16).padLeft(2, '0')}'
           '${b.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color)';
  }
}