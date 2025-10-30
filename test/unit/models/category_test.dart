import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards_app/models/category.dart';

void main() {
  group('Category Model Tests', () {
    test('should create category with required fields', () {
      final category = Category(name: 'Math');

      expect(category.name, 'Math');
      expect(category.id, isNotEmpty);
      expect(category.color, isNotEmpty);
      expect(category.createdAt, isA<DateTime>());
    });

    test('should create category with custom fields', () {
      final createdAt = DateTime(2023, 1, 1);
      final category = Category(
        id: 'custom-id',
        name: 'Science',
        color: 'ff0000',
        createdAt: createdAt,
      );

      expect(category.id, 'custom-id');
      expect(category.name, 'Science');
      expect(category.color, 'ff0000');
      expect(category.createdAt, createdAt);
    });

    test('should copy category with updated fields', () {
      final original = Category(name: 'Original');
      final updated = original.copyWith(name: 'Updated');

      expect(updated.id, original.id);
      expect(updated.name, 'Updated');
      expect(updated.color, original.color);
      expect(updated.createdAt, original.createdAt);
    });

    test('should convert to and from map correctly', () {
      final category = Category(
        id: 'test-id',
        name: 'Test Category',
        color: 'ff0000',
        createdAt: DateTime(2023, 1, 1),
      );

      final map = category.toMap();
      final fromMap = Category.fromMap(map);

      expect(fromMap.id, category.id);
      expect(fromMap.name, category.name);
      expect(fromMap.color, category.color);
      expect(fromMap.createdAt, category.createdAt);
    });

    test('should get color value correctly', () {
      final category = Category(
        name: 'Test',
        color: 'f44336', // Red color hex
      );

      expect((category.colorValue.r * 255).round(), closeTo(244, 1));
      expect((category.colorValue.g * 255).round(), closeTo(67, 1));
      expect((category.colorValue.b * 255).round(), closeTo(54, 1));
    });

    test('should handle invalid color gracefully', () {
      final category = Category(
        name: 'Test',
        color: 'invalid-color',
      );

      expect(category.colorValue, Colors.blue); // Default fallback
    });

    test('should validate correctly', () {
      final validCategory = Category(name: 'Valid Name');
      final invalidCategory = Category(name: '');

      expect(validCategory.isValid(), true);
      expect(invalidCategory.isValid(), false);
    });

    test('should validate name field', () {
      final category = Category(name: '');
      expect(category.validateName(), 'Category name cannot be empty');

      final longName = 'a' * 51;
      final categoryLong = category.copyWith(name: longName);
      expect(categoryLong.validateName(), 'Category name must be less than 50 characters');

      final validCategory = category.copyWith(name: 'Valid Name');
      expect(validCategory.validateName(), null);
    });

    test('should create category with predefined color', () {
      final category = Category.withPredefinedColor(
        name: 'Test',
        color: Colors.green,
      );

      expect(category.name, 'Test');
      expect((category.colorValue.g * 255).round(), closeTo((Colors.green.g * 255).round(), 1));
    });

    test('should have predefined colors available', () {
      expect(Category.predefinedColors, isNotEmpty);
      expect(Category.predefinedColors.length, 10);
      expect(Category.predefinedColors.contains(Colors.blue), true);
      expect(Category.predefinedColors.contains(Colors.green), true);
    });

    test('should implement equality correctly', () {
      final category1 = Category(id: 'same-id', name: 'Name 1');
      final category2 = Category(id: 'same-id', name: 'Name 2');
      final category3 = Category(id: 'different-id', name: 'Name 1');

      expect(category1, category2); // Same ID
      expect(category1, isNot(category3)); // Different ID
    });
  });
}