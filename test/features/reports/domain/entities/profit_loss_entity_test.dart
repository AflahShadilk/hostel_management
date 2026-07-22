import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/reports/domain/entities/profit_loss_entity.dart';

void main() {
  group('ProfitLossEntity', () {
    test('calculates totalRevenue correctly', () {
      const entity = ProfitLossEntity(
        rentRevenue: 1000,
        damageChargeRevenue: 200,
        otherRevenue: 50,
      );
      expect(entity.totalRevenue, 1250);
    });

    test('calculates netProfit correctly (profit scenario)', () {
      const entity = ProfitLossEntity(
        rentRevenue: 1000,
        totalExpenses: 800,
      );
      expect(entity.netProfit, 200);
      expect(entity.isProfit, true);
    });

    test('calculates netProfit correctly (loss scenario)', () {
      const entity = ProfitLossEntity(
        rentRevenue: 1000,
        totalExpenses: 1200,
      );
      expect(entity.netProfit, -200);
      expect(entity.isProfit, false);
    });

    test('calculates profitMargin correctly when revenue > 0', () {
      const entity = ProfitLossEntity(
        rentRevenue: 1000,
        totalExpenses: 800,
      );
      // Net Profit = 200, Revenue = 1000 -> 20%
      expect(entity.profitMargin, 20.0);
    });

    test('calculates profitMargin as 0 when revenue is 0', () {
      const entity = ProfitLossEntity(
        rentRevenue: 0,
        totalExpenses: 500,
      );
      expect(entity.profitMargin, 0.0);
    });

    test('calculates profitMargin as negative when loss', () {
      const entity = ProfitLossEntity(
        rentRevenue: 1000,
        totalExpenses: 1200,
      );
      // Net Profit = -200, Revenue = 1000 -> -20%
      expect(entity.profitMargin, -20.0);
    });
  });
}
