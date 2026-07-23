import 'package:equatable/equatable.dart';

class ProfitLossEntity extends Equatable {
  final double rentRevenue;
  final double damageChargeRevenue;
  final double otherRevenue;
  final double totalExpenses;

  const ProfitLossEntity({
    this.rentRevenue = 0.0,
    this.damageChargeRevenue = 0.0,
    this.otherRevenue = 0.0,
    this.totalExpenses = 0.0,
  });

  double get totalRevenue => rentRevenue + damageChargeRevenue + otherRevenue;

  double get netProfit => totalRevenue - totalExpenses;

  bool get isProfit => netProfit >= 0;

  double get profitMargin {
    if (totalRevenue <= 0) return 0.0;
    return (netProfit / totalRevenue) * 100;
  }

  @override
  List<Object?> get props => [
        rentRevenue,
        damageChargeRevenue,
        otherRevenue,
        totalExpenses,
      ];
}
