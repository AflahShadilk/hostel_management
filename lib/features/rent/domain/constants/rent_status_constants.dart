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

/// Known payment methods for Rent payments.
///
/// The [payments] table has no SQL CHECK constraint on [payment_method],
/// so this class acts as the single source of truth for valid values.
abstract final class PaymentMethod {
  static const String cash = 'cash';
  static const String bankTransfer = 'bank_transfer';
  static const String upi = 'upi';
  static const String cheque = 'cheque';
  static const String other = 'other';

  static const List<String> values = <String>[
    cash,
    bankTransfer,
    upi,
    cheque,
    other,
  ];
}

abstract final class DepositStatus {
  static const String pending = 'pending';
  static const String held = 'held';
  static const String refunded = 'refunded';
  static const String forfeited = 'forfeited';

  static const List<String> values = <String>[
    pending,
    held,
    refunded,
    forfeited,
  ];
}
