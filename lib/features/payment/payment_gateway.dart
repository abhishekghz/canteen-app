/// Result of a payment attempt.
class PaymentResult {
  final bool success;
  final String? reference;
  final String? error;
  const PaymentResult.ok(this.reference) : success = true, error = null;
  const PaymentResult.failed(this.error) : success = false, reference = null;
}

/// Payment abstraction. Swap [StubPaymentGateway] for a real one (Razorpay,
/// Stripe, etc.) later without touching any UI.
abstract class PaymentGateway {
  Future<PaymentResult> pay({
    required int amountPaise,
    required String orderRef,
  });
}

/// Placeholder gateway used until a real provider is integrated.
/// Always succeeds after a short simulated delay.
class StubPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay({
    required int amountPaise,
    required String orderRef,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return PaymentResult.ok('STUB-${DateTime.now().millisecondsSinceEpoch}');
  }
}
