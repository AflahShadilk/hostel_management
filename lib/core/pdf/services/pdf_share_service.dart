import 'package:share_plus/share_plus.dart';

/// Opens the platform share sheet for a previously saved PDF.
class PdfShareService {
  const PdfShareService();

  Future<void> sharePdf({
    required String filePath,
    String? subject,
    String? text,
  }) {
    return Share.shareXFiles(
      <XFile>[XFile(filePath)],
      subject: subject,
      text: text,
    );
  }
}
