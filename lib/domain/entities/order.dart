import 'menu_day.dart';

enum OrderStatus { pending, confirmed }

enum PaymentStatus { unpaid, paid, refunded }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.paid => 'Paid',
        PaymentStatus.refunded => 'Refunded',
      };
}

/// Base class for a single line in an order/cart.
sealed class OrderLine {
  final String date; // yyyy-MM-dd the item is for
  final int lineTotal; // paise
  const OrderLine({required this.date, required this.lineTotal});

  Map<String, dynamic> toMap();

  static OrderLine fromMap(Map<String, dynamic> m) {
    return switch (m['kind'] as String) {
      'meal' => MealLine.fromMap(m),
      'snack' => SnackLine.fromMap(m),
      _ => throw ArgumentError('Unknown line kind ${m['kind']}'),
    };
  }
}

/// A booked meal (breakfast/lunch/dinner) with optional extras + packing.
class MealLine extends OrderLine {
  final MealType mealType;
  final int extraRoti;
  final int extraSabji;
  final bool packed;

  const MealLine({
    required this.mealType,
    required super.date,
    required super.lineTotal,
    this.extraRoti = 0,
    this.extraSabji = 0,
    this.packed = false,
  });

  @override
  Map<String, dynamic> toMap() => {
        'kind': 'meal',
        'mealType': mealType.name,
        'date': date,
        'extraRoti': extraRoti,
        'extraSabji': extraSabji,
        'packed': packed,
        'lineTotal': lineTotal,
      };

  factory MealLine.fromMap(Map<String, dynamic> m) => MealLine(
        mealType: MealType.values.byName(m['mealType'] as String),
        date: m['date'] as String,
        extraRoti: (m['extraRoti'] as num?)?.toInt() ?? 0,
        extraSabji: (m['extraSabji'] as num?)?.toInt() ?? 0,
        packed: m['packed'] as bool? ?? false,
        lineTotal: (m['lineTotal'] as num).toInt(),
      );
}

/// A booked snack (tea/coffee + snacks) in a slot, optionally early-booked.
class SnackLine extends OrderLine {
  final String slotId;
  final int teaCoffeeQty;
  final int snackQty;
  final bool earlyBooking;

  const SnackLine({
    required this.slotId,
    required super.date,
    required super.lineTotal,
    this.teaCoffeeQty = 0,
    this.snackQty = 0,
    this.earlyBooking = false,
  });

  @override
  Map<String, dynamic> toMap() => {
        'kind': 'snack',
        'slotId': slotId,
        'date': date,
        'teaCoffeeQty': teaCoffeeQty,
        'snackQty': snackQty,
        'earlyBooking': earlyBooking,
        'lineTotal': lineTotal,
      };

  factory SnackLine.fromMap(Map<String, dynamic> m) => SnackLine(
        slotId: m['slotId'] as String,
        date: m['date'] as String,
        teaCoffeeQty: (m['teaCoffeeQty'] as num?)?.toInt() ?? 0,
        snackQty: (m['snackQty'] as num?)?.toInt() ?? 0,
        earlyBooking: m['earlyBooking'] as bool? ?? false,
        lineTotal: (m['lineTotal'] as num).toInt(),
      );
}

class Order {
  final String id;
  final String uid;
  final DateTime createdAt;
  final List<OrderLine> lines;
  final int total; // paise
  final OrderStatus status;
  final PaymentStatus paymentStatus;

  const Order({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.lines,
    required this.total,
    this.status = OrderStatus.confirmed,
    this.paymentStatus = PaymentStatus.unpaid,
  });

  Order copyWith({PaymentStatus? paymentStatus, OrderStatus? status}) => Order(
        id: id,
        uid: uid,
        createdAt: createdAt,
        lines: lines,
        total: total,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((l) => l.toMap()).toList(),
        'total': total,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
      };

  factory Order.fromMap(String id, Map<String, dynamic> m) => Order(
        id: id,
        uid: m['uid'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        lines: (m['lines'] as List)
            .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (m['total'] as num).toInt(),
        status: OrderStatus.values.byName(m['status'] as String? ?? 'confirmed'),
        paymentStatus: PaymentStatus.values
            .byName(m['paymentStatus'] as String? ?? 'unpaid'),
      );
}
