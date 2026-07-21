class CheckoutRequest {
  final int stayId;
  final double damageAmount;
  final String? notes;

  const CheckoutRequest({
    required this.stayId,
    this.damageAmount = 0,
    this.notes,
  });
}
