import 'package:canteen_app/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats whole rupees', () => expect(formatRupees(5000), '₹50'));
  test('formats paise', () => expect(formatRupees(550), '₹5.50'));
  test('formats zero', () => expect(formatRupees(0), '₹0'));
  test('rupees helper', () => expect(rupees(15), 1500));
  test('formats single-digit paise with padding',
      () => expect(formatRupees(505), '₹5.05'));
}
