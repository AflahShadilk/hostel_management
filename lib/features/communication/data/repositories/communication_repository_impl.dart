import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/communication_repository.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl();

  @override
  Future<CommunicationResult> openWhatsAppChat(String phoneNumber) {
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhoneNumber == null) {
      return Future.value(
        const CommunicationResult.failure('A valid phone number is required.'),
      );
    }

    return _launch(
      Uri(
        scheme: 'whatsapp',
        host: 'send',
        queryParameters: <String, String>{'phone': normalizedPhoneNumber},
      ),
      unavailableMessage: 'WhatsApp is not available on this device.',
    );
  }

  @override
  Future<CommunicationResult> sendWhatsAppMessage(
    String phoneNumber,
    String message,
  ) {
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhoneNumber == null) {
      return Future.value(
        const CommunicationResult.failure('A valid phone number is required.'),
      );
    }
    if (message.trim().isEmpty) {
      return Future.value(
        const CommunicationResult.failure('A message is required.'),
      );
    }

    return _launch(
      Uri(
        scheme: 'whatsapp',
        host: 'send',
        queryParameters: <String, String>{
          'phone': normalizedPhoneNumber,
          'text': message,
        },
      ),
      unavailableMessage: 'WhatsApp is not available on this device.',
    );
  }

  @override
  Future<CommunicationResult> makePhoneCall(String phoneNumber) {
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhoneNumber == null) {
      return Future.value(
        const CommunicationResult.failure('A valid phone number is required.'),
      );
    }

    return _launch(
      Uri(scheme: 'tel', path: normalizedPhoneNumber),
      unavailableMessage: 'Phone calls are not available on this device.',
    );
  }

  @override
  Future<CommunicationResult> sendSms(String phoneNumber, String message) {
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhoneNumber == null) {
      return Future.value(
        const CommunicationResult.failure('A valid phone number is required.'),
      );
    }
    if (message.trim().isEmpty) {
      return Future.value(
        const CommunicationResult.failure('A message is required.'),
      );
    }

    return _launch(
      Uri(
        scheme: 'sms',
        path: normalizedPhoneNumber,
        queryParameters: <String, String>{'body': message},
      ),
      unavailableMessage: 'SMS is not available on this device.',
    );
  }

  @override
  Future<CommunicationResult> shareText(String text) async {
    if (text.trim().isEmpty) {
      return const CommunicationResult.failure('Text to share is required.');
    }

    try {
      final result = await Share.share(text);
      if (result.status == ShareResultStatus.unavailable) {
        return const CommunicationResult.failure(
          'Text sharing is not available on this device.',
        );
      }
      return const CommunicationResult.success();
    } catch (_) {
      return const CommunicationResult.failure('Unable to share text.');
    }
  }

  @override
  Future<CommunicationResult> shareReceiptText(String receiptText) =>
      shareText(receiptText);

  Future<CommunicationResult> _launch(
    Uri uri, {
    required String unavailableMessage,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return CommunicationResult.failure(unavailableMessage);
      }
      return const CommunicationResult.success();
    } catch (_) {
      return CommunicationResult.failure(unavailableMessage);
    }
  }

  String? _normalizePhoneNumber(String phoneNumber) {
    final compactNumber = phoneNumber.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final hasCountryCode = compactNumber.startsWith('+');
    final digits = hasCountryCode ? compactNumber.substring(1) : compactNumber;

    if (!RegExp(r'^\d{6,15}$').hasMatch(digits)) {
      return null;
    }

    return digits;
  }
}
