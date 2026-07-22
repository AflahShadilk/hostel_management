import 'checkout_receipt_preview_view_model.dart';

class CheckoutListItemViewModel {
  const CheckoutListItemViewModel({
    required this.stayId,
    required this.tenantName,
    required this.phoneNumber,
    required this.roomName,
    required this.bedName,
    required this.checkInDate,
    required this.monthlyRent,
    required this.pendingRent,
    required this.status,
    this.receiptPreview,
  });

  final int stayId;
  final String tenantName;
  final String phoneNumber;
  final String roomName;
  final String bedName;
  final DateTime checkInDate;
  final double monthlyRent;
  final double pendingRent;
  final String status;
  final CheckoutReceiptPreviewViewModel? receiptPreview;
}
