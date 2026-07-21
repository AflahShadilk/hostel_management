import 'package:equatable/equatable.dart';

class ExpenseSummaryEntity extends Equatable {
  final double todayTotal;
  final double monthTotal;
  final double yearTotal;
  final double overallTotal;

  const ExpenseSummaryEntity({
    required this.todayTotal,
    required this.monthTotal,
    required this.yearTotal,
    required this.overallTotal,
  });

  @override
  List<Object?> get props => <Object?>[
        todayTotal,
        monthTotal,
        yearTotal,
        overallTotal,
      ];
}
