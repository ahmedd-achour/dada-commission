import '../models/payment.dart';

/// Outcome of a payment attempt.
class PaymentResult {
  const PaymentResult._(this.succeeded, this.orderId, this.error);

  const PaymentResult.success(String orderId) : this._(true, orderId, null);
  const PaymentResult.failure(String error) : this._(false, null, error);

  final bool succeeded;

  /// Click to Pay order id (stored in `payments/{id}.providerOrderId`).
  final String? orderId;
  final String? error;
}

/// Pays an amount through the payment provider.
abstract class PaymentGateway {
  Future<PaymentResult> pay({
    required int amountMillimes,
    required PaymentPurpose purpose,
    required String description,
  });
}

/// Click to Pay (ClicToPay) integration — to wire once the API details are
/// shared.
///
/// Expected flow (keeps every secret server-side):
/// 1. The app calls a Cloud Function `createPayment(purpose, requestId)`.
///    The function recomputes the amount from the request (never trusts the
///    app), registers the order with Click to Pay and returns the payment
///    page URL + order id.
/// 2. The app opens that URL (web view / browser); the client pays.
/// 3. Click to Pay redirects back; the function checks the order status with
///    Click to Pay, then in ONE Firestore transaction:
///    payment -> succeeded, request -> open, ambassador wallet += 8 % in DC.
/// 4. The app only listens to `payments/{id}` / `requests/{id}`.
class ClickToPayGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay({
    required int amountMillimes,
    required PaymentPurpose purpose,
    required String description,
  }) async {
    throw UnimplementedError('Click to Pay API not wired yet.');
  }
}

/// Demo gateway used in guest mode: always succeeds after a short delay.
class DemoPaymentGateway implements PaymentGateway {
  const DemoPaymentGateway({this.delay = const Duration(milliseconds: 600)});
  final Duration delay;

  @override
  Future<PaymentResult> pay({
    required int amountMillimes,
    required PaymentPurpose purpose,
    required String description,
  }) async {
    await Future<void>.delayed(delay);
    return PaymentResult.success(
      'demo_${DateTime.now().microsecondsSinceEpoch}',
    );
  }
}
