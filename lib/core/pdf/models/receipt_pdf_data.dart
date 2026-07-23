/// Export-ready content for a receipt or settlement PDF.
///
/// The model intentionally remains independent from feature entities and
/// persistence models.
class ReceiptPdfData {
  const ReceiptPdfData({
    required this.title,
    required this.documentNumber,
    required this.issuedAt,
    required this.businessName,
    required this.recipientName,
    required this.lineItems,
    required this.totalLabel,
    required this.totalAmount,
    this.businessAddress,
    this.businessPhone,
    this.recipientDetails,
    this.notes,
    this.currencyPrefix = 'INR ',
  });

  final String title;
  final String documentNumber;
  final DateTime issuedAt;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String recipientName;
  final String? recipientDetails;
  final List<ReceiptPdfLineItem> lineItems;
  final String totalLabel;
  final double totalAmount;
  final String? notes;
  final String currencyPrefix;
}

/// A printable charge, payment, refund, or other receipt line.
class ReceiptPdfLineItem {
  const ReceiptPdfLineItem({
    required this.description,
    required this.amount,
    this.detail,
  });

  final String description;
  final String? detail;
  final double amount;
}
