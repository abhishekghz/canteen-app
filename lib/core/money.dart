// Money helpers. Internally money is stored as integer **paise** to avoid
// floating point errors. Format only at display time.

/// Formats [paise] as an INR string. `5000 -> "₹50"`, `550 -> "₹5.50"`.
String formatRupees(int paise) {
  final rupees = paise ~/ 100;
  final remainder = paise % 100;
  if (remainder == 0) return '₹$rupees';
  return '₹$rupees.${remainder.toString().padLeft(2, '0')}';
}

/// Convenience for building prices from whole rupees.
int rupees(int r) => r * 100;
