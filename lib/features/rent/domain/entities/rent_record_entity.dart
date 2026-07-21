import 'package:equatable/equatable.dart';

// Month name lookup — avoids adding the intl package.
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';

class RentRecordEntity extends Equatable {
  final int? id;
  final int stayId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final DateTime generatedAt;
  final double amountDue;
  final double amountPaid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentRecordEntity({
    this.id,
    required this.stayId,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.generatedAt,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculated outstanding balance.
  double get outstanding => amountDue - amountPaid;

  /// Human-readable billing period, e.g. "10 Jul 2026 – 09 Aug 2026".
  String get formattedPeriod => '${_fmtDate(startDate)} – ${_fmtDate(endDate)}';

  @override
  List<Object?> get props => [
        id,
        stayId,
        startDate,
        endDate,
        dueDate,
        generatedAt,
        amountDue,
        amountPaid,
        status,
        createdAt,
        updatedAt,
      ];
}
