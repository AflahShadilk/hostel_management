import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Persists generated PDF bytes in the application documents directory.
class PdfStorageService {
  const PdfStorageService();

  Future<String> savePdf({
    required Uint8List bytes,
    required String fileName,
    required String folderName,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final folderSegments = folderName
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.trim().isNotEmpty)
        .map(_sanitizePathSegment);
    final pdfDirectory = Directory(
      path.joinAll(<String>[documentsDirectory.path, ...folderSegments]),
    );

    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    final normalizedFileName = _normalizeFileName(fileName);
    final file = await _nextAvailableFile(pdfDirectory, normalizedFileName);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _normalizeFileName(String value) {
    final withExtension = value.toLowerCase().endsWith('.pdf')
        ? value
        : '$value.pdf';
    final sanitized = _sanitizePathSegment(withExtension);
    return sanitized.isEmpty || sanitized == '.pdf' ? 'document.pdf' : sanitized;
  }

  String _sanitizePathSegment(String value) => value
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .trim();

  Future<File> _nextAvailableFile(Directory directory, String fileName) async {
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    var candidate = File(path.join(directory.path, fileName));
    var index = 1;

    while (await candidate.exists()) {
      candidate = File(
        path.join(directory.path, '$baseName ($index)$extension'),
      );
      index++;
    }

    return candidate;
  }
}
