/// Status values persisted by the Rent Management database schema.
///
/// SQL CHECK constraints use the same values through [RentLocalSchema], while
/// future rent code can use these constants instead of repeating raw strings.
abstract final class StayStatus {
  static const String active = 'active';
  static const String checkoutPending = 'checkout_pending';
  static const String checkedOut = 'checked_out';
  static const String closed = 'closed';

  static const List<String> values = <String>[
    active,
    checkoutPending,
    checkedOut,
    closed,
  ];
}

abstract final class RentStatus {
  static const String pending = 'pending';
  static const String partial = 'partial';
  static const String paid = 'paid';
  static const String overdue = 'overdue';

  static const List<String> values = <String>[pending, partial, paid, overdue];
}

abstract final class PaymentStatus {
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = <String>[completed, cancelled];
}

abstract final class SettlementStatus {
  static const String draft = 'draft';
  static const String completed = 'completed';

  static const List<String> values = <String>[draft, completed];
}
