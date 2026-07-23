import '../../domain/entities/checkout_settlement_entity.dart';

/// Read-only receipt-preview data derived from an existing settlement record.
class CheckoutReceiptPreviewViewModel {
  const CheckoutReceiptPreviewViewModel({required this.settlement});

  final CheckoutSettlementEntity settlement;
}
