/// Parameters required to insert or update the current-month rent record
/// at checkout time.
///
/// The datasource uses this to decide whether to UPDATE an existing record
/// or INSERT a new one, based on [currentMonthPrefix].
class UpsertRentRecordCommand {
  /// The stay this rent record belongs to.
  final int stayId;

  /// YYYY-MM prefix of the checkout month used to find an existing record.
  final String currentMonthPrefix;

  /// Effective start of the current-month billing period
  /// (max of check-in date and first day of checkout month).
  final DateTime effectiveStartDate;

  /// The checkout date — used as the record's end date.
  final DateTime checkoutDate;

  /// Calculated prorated charge for the checkout month.
  final double currentMonthCharge;

  /// Status determined by the checkout rent calculator.
  final String status;

  const UpsertRentRecordCommand({
    required this.stayId,
    required this.currentMonthPrefix,
    required this.effectiveStartDate,
    required this.checkoutDate,
    required this.currentMonthCharge,
    this.status = 'pending',
  });
}

