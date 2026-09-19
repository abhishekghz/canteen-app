import '../../core/money.dart';

/// All prices are stored as integer **paise** and are admin-editable.
class Pricing {
  final int breakfast;
  final int lunch;
  final int dinner;
  final int roti;
  final int sabji;
  final int packing;
  final int teaCoffee;
  final int snack;
  final int earlyBookingDiscount;

  const Pricing({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.roti,
    required this.sabji,
    required this.packing,
    required this.teaCoffee,
    required this.snack,
    required this.earlyBookingDiscount,
  });

  /// Seeded defaults from the spec (₹).
  factory Pricing.seedDefaults() => Pricing(
        breakfast: rupees(50),
        lunch: rupees(50),
        dinner: rupees(50),
        roti: rupees(5),
        sabji: rupees(20),
        packing: rupees(15),
        teaCoffee: rupees(10),
        snack: rupees(20),
        earlyBookingDiscount: 0,
      );

  Pricing copyWith({
    int? breakfast,
    int? lunch,
    int? dinner,
    int? roti,
    int? sabji,
    int? packing,
    int? teaCoffee,
    int? snack,
    int? earlyBookingDiscount,
  }) =>
      Pricing(
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        roti: roti ?? this.roti,
        sabji: sabji ?? this.sabji,
        packing: packing ?? this.packing,
        teaCoffee: teaCoffee ?? this.teaCoffee,
        snack: snack ?? this.snack,
        earlyBookingDiscount:
            earlyBookingDiscount ?? this.earlyBookingDiscount,
      );

  Map<String, dynamic> toMap() => {
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'roti': roti,
        'sabji': sabji,
        'packing': packing,
        'teaCoffee': teaCoffee,
        'snack': snack,
        'earlyBookingDiscount': earlyBookingDiscount,
      };

  factory Pricing.fromMap(Map<String, dynamic> m) => Pricing(
        breakfast: (m['breakfast'] as num).toInt(),
        lunch: (m['lunch'] as num).toInt(),
        dinner: (m['dinner'] as num).toInt(),
        roti: (m['roti'] as num).toInt(),
        sabji: (m['sabji'] as num).toInt(),
        packing: (m['packing'] as num).toInt(),
        teaCoffee: (m['teaCoffee'] as num).toInt(),
        snack: (m['snack'] as num).toInt(),
        earlyBookingDiscount: (m['earlyBookingDiscount'] as num).toInt(),
      );
}
