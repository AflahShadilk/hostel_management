import '../services/communication_service.dart';
import '../../domain/repositories/communication_repository.dart';

/// Implements [CommunicationRepository] by delegating every platform action to
/// [CommunicationService].
///
/// This class is responsible for:
///  * phone-number validation / normalisation
///  * translating raw boolean results from [CommunicationService] into the
///    presentation-friendly [CommunicationResult] type
///
/// It never imports [url_launcher] or [share_plus] directly.
class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl(this._service);

  final CommunicationService _service;

  // ---------------------------------------------------------------------------
  // WhatsApp
  // ---------------------------------------------------------------------------

  @override
  Future<CommunicationResult> openWhatsAppChat(String phoneNumber) async {
    final number = _normalizePhoneNumber(phoneNumber);
    if (number == null) {
      return const CommunicationResult.failure(
          'A valid phone number is required.');
    }
    final launched = await _service.launchWhatsApp(number);
    return launched
        ? const CommunicationResult.success()
        : const CommunicationResult.failure(
            'WhatsApp is not available on this device.');
  }

  @override
  Future<CommunicationResult> sendWhatsAppMessage(
    String phoneNumber,
    String message,
  ) async {
    final number = _normalizePhoneNumber(phoneNumber);
    if (number == null) {
      return const CommunicationResult.failure(
          'A valid phone number is required.');
    }
    if (message.trim().isEmpty) {
      return const CommunicationResult.failure('A message is required.');
    }
    final launched = await _service.launchWhatsAppWithMessage(number, message);
    return launched
        ? const CommunicationResult.success()
        : const CommunicationResult.failure(
            'WhatsApp is not available on this device.');
  }

  // ---------------------------------------------------------------------------
  // Phone call
  // ---------------------------------------------------------------------------

  @override
  Future<CommunicationResult> makePhoneCall(String phoneNumber) async {
    final number = _normalizePhoneNumber(phoneNumber);
    if (number == null) {
      return const CommunicationResult.failure(
          'A valid phone number is required.');
    }
    final launched = await _service.launchPhone(number);
    return launched
        ? const CommunicationResult.success()
        : const CommunicationResult.failure(
            'Phone calls are not available on this device.');
  }

  // ---------------------------------------------------------------------------
  // SMS
  // ---------------------------------------------------------------------------

  @override
  Future<CommunicationResult> sendSms(
      String phoneNumber, String message) async {
    final number = _normalizePhoneNumber(phoneNumber);
    if (number == null) {
      return const CommunicationResult.failure(
          'A valid phone number is required.');
    }
    if (message.trim().isEmpty) {
      return const CommunicationResult.failure('A message is required.');
    }
    final launched = await _service.launchSms(number, message);
    return launched
        ? const CommunicationResult.success()
        : const CommunicationResult.failure(
            'SMS is not available on this device.');
  }

  // ---------------------------------------------------------------------------
  // Share
  // ---------------------------------------------------------------------------

  @override
  Future<CommunicationResult> shareText(String text) async {
    if (text.trim().isEmpty) {
      return const CommunicationResult.failure('Text to share is required.');
    }
    final shared = await _service.shareText(text);
    return shared
        ? const CommunicationResult.success()
        : const CommunicationResult.failure(
            'Text sharing is not available on this device.');
  }

  @override
  Future<CommunicationResult> shareReceiptText(String receiptText) =>
      shareText(receiptText);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Strips non-digit characters and validates the result.
  /// Returns the compact digit-only string on success, or [null] if invalid.
  String? _normalizePhoneNumber(String phoneNumber) {
    final compact = phoneNumber.trim().replaceAll(RegExp(r'[\s\-()+]'), '');
    if (!RegExp(r'^\d{6,15}$').hasMatch(compact)) return null;
    return compact;
  }
}
