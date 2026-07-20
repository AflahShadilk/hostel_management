/// The result of a platform communication action.
class CommunicationResult {
  const CommunicationResult._({required this.isSuccess, this.message});

  const CommunicationResult.success() : this._(isSuccess: true);

  const CommunicationResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
}

abstract interface class CommunicationRepository {
  Future<CommunicationResult> openWhatsAppChat(String phoneNumber);

  Future<CommunicationResult> sendWhatsAppMessage(
    String phoneNumber,
    String message,
  );

  Future<CommunicationResult> makePhoneCall(String phoneNumber);

  Future<CommunicationResult> sendSms(String phoneNumber, String message);

  Future<CommunicationResult> shareText(String text);

  Future<CommunicationResult> shareReceiptText(String receiptText);
}
