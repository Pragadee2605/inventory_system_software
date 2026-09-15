import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Business Logic Tests', () {
    test('Stock Calculation - Addition', () {
      int currentStock = 10;
      int quantityAdded = 5;
      int expectedStock = 15;
      expect(currentStock + quantityAdded, expectedStock);
    });

    test('Stock Calculation - Subtraction', () {
      int currentStock = 10;
      int quantityRemoved = 3;
      int expectedStock = 7;
      expect(currentStock - quantityRemoved, expectedStock);
    });
    
    test('Low Stock Warning Logic', () {
      int currentStock = 4;
      int minStockLevel = 5;
      bool isLowStock = currentStock <= minStockLevel;
      expect(isLowStock, true);
    });
  });
}
