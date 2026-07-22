class CheckoutRequest {
  final int stayId;
  final double damageAmount;
  final double otherCharges;
  final DateTime? checkoutDate;
  final String? notes;

  const CheckoutRequest({
    required this.stayId,
    this.damageAmount = 0,
    this.otherCharges = 0,
    this.checkoutDate,
    this.notes,
  });
}
