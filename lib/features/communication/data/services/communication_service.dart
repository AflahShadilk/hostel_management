import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Low-level platform integration layer.
///
/// This is the **only** place in the feature that touches [url_launcher] or
/// [share_plus] directly.  All higher layers (repository, cubit, widgets)
/// must remain ignorant of these packages.
class CommunicationService {
  const CommunicationService();

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  Future<bool> launchPhone(String normalizedNumber) =>
      _launch(Uri(scheme: 'tel', path: normalizedNumber));

  // ---------------------------------------------------------------------------
  // WhatsApp
  // ---------------------------------------------------------------------------

  Future<bool> launchWhatsApp(String normalizedNumber) => _launch(
        Uri(
          scheme: 'whatsapp',
          host: 'send',
          queryParameters: <String, String>{'phone': normalizedNumber},
        ),
      );

  Future<bool> launchWhatsAppWithMessage(
    String normalizedNumber,
    String message,
  ) =>
      _launch(
        Uri(
          scheme: 'whatsapp',
          host: 'send',
          queryParameters: <String, String>{
            'phone': normalizedNumber,
            'text': message,
          },
        ),
      );

  // ---------------------------------------------------------------------------
  // SMS
  // ---------------------------------------------------------------------------

  Future<bool> launchSms(String normalizedNumber, String body) => _launch(
        Uri(
          scheme: 'sms',
          path: normalizedNumber,
          queryParameters: <String, String>{'body': body},
        ),
      );

  // ---------------------------------------------------------------------------
  // Share
  // ---------------------------------------------------------------------------

  Future<bool> shareText(String text) async {
    try {
      final result = await Share.share(text);
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
