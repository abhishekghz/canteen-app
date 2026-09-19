import 'menu_day.dart';

enum CouponStatus { active, redeemed, expired }

extension CouponStatusX on CouponStatus {
  String get label => switch (this) {
        CouponStatus.active => 'Active',
        CouponStatus.redeemed => 'Redeemed',
        CouponStatus.expired => 'Expired',
      };
}

/// A prepaid meal pass. Buy in advance, redeem when booking.
class Coupon {
  final String id;
  final String uid;
  final MealType mealType;
  final String code;
  final CouponStatus status;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String? redeemedOrderId;

  const Coupon({
    required this.id,
    required this.uid,
    required this.mealType,
    required this.code,
    required this.status,
    required this.purchasedAt,
    required this.expiresAt,
    this.redeemedOrderId,
  });

  Coupon copyWith({CouponStatus? status, String? redeemedOrderId}) => Coupon(
        id: id,
        uid: uid,
        mealType: mealType,
        code: code,
        status: status ?? this.status,
        purchasedAt: purchasedAt,
        expiresAt: expiresAt,
        redeemedOrderId: redeemedOrderId ?? this.redeemedOrderId,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'mealType': mealType.name,
        'code': code,
        'status': status.name,
        'purchasedAt': purchasedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'redeemedOrderId': redeemedOrderId,
      };

  factory Coupon.fromMap(String id, Map<String, dynamic> m) => Coupon(
        id: id,
        uid: m['uid'] as String,
        mealType: MealType.values.byName(m['mealType'] as String),
        code: m['code'] as String,
        status: CouponStatus.values.byName(m['status'] as String),
        purchasedAt: DateTime.parse(m['purchasedAt'] as String),
        expiresAt: DateTime.parse(m['expiresAt'] as String),
        redeemedOrderId: m['redeemedOrderId'] as String?,
      );
}
