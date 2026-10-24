import '../../auth/data/auth_repository.dart';
import '../domain/activity.dart';
import 'play_repository.dart';

/// A saved way to pay, as listed on the payment sheet.
class PayMethod {
  const PayMethod({
    required this.id,
    required this.title,
    required this.detail,
  });
  final String id;
  final String title;
  final String detail;
}

/// Takes payment for paid Meets, tournaments and events. Card payments need
/// a payment provider (for example Stripe) on the server; until one is
/// connected, [SupabasePaymentGateway] reports that plainly.
abstract interface class PaymentGateway {
  Future<List<PayMethod>> methods();

  /// Charges the player and confirms their spot. Returns the receipt.
  Future<Receipt> pay({
    required Activity activity,
    required PayMethod method,
    String? guestName,
    double? guestLevel,
    required String email,
  });
}

class SupabasePaymentGateway implements PaymentGateway {
  @override
  Future<List<PayMethod>> methods() async => const [];

  @override
  Future<Receipt> pay({
    required Activity activity,
    required PayMethod method,
    String? guestName,
    double? guestLevel,
    required String email,
  }) async {
    throw const AuthFailure(
      "Card payments aren't switched on yet. Free Meets work now; paid ones open once payments are connected.",
    );
  }
}

/// Approves every payment and confirms the spot, using the design's sample card.
class DemoPaymentGateway implements PaymentGateway {
  DemoPaymentGateway(this._play);
  final DemoPlayRepository _play;
  int _receipts = 47;

  @override
  Future<List<PayMethod>> methods() async => const [
    PayMethod(id: 'card', title: 'Visa ending 4242', detail: 'Default card'),
    PayMethod(id: 'wallet', title: 'Wallet', detail: 'Balance S\$ 12.50'),
  ];

  @override
  Future<Receipt> pay({
    required Activity activity,
    required PayMethod method,
    String? guestName,
    double? guestLevel,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final spots =
        (activity.myStatus == MyStatus.joined ? 0 : 1) +
        (guestName == null ? 0 : 1);
    _play.markPaid(activity.id, guestName: guestName);
    final now = DateTime.now();
    _receipts++;
    return Receipt(
      activityId: activity.id,
      activityKind: activity.kind,
      receiptNo:
          'OG-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_receipts.toString().padLeft(4, '0')}',
      activityTitle: activity.title,
      activityStartsAt: activity.startsAt,
      paidWith: method.title,
      feeCents: activity.feeCents * spots,
      platformFeeCents: activity.platformCents * spots,
      email: email,
    );
  }
}
