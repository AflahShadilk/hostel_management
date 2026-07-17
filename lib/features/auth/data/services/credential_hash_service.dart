import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service responsible for cryptographically deriving passwords and PINs.
///
/// NOTE: This implementation uses SHA-256 HMAC because of project time and
/// native-dependency constraints. In a production internet-facing system, a
/// dedicated KDF (Key Derivation Function) such as Argon2id, scrypt, or PBKDF2
/// with an appropriate work factor should be used instead.
class CredentialHashService {
  const CredentialHashService();

  /// Generates a cryptographically secure random salt of the given length.
  String generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Hashes a credential (password or PIN) using HMAC-SHA-256 and the provided salt.
  String hashCredential({
    required String credential,
    required String salt,
  }) {
    final hmac = Hmac(sha256, utf8.encode(salt));
    final digest = hmac.convert(utf8.encode(credential));
    return base64UrlEncode(digest.bytes);
  }

  /// Safely compares two hashes using a constant-time comparison to prevent
  /// timing attacks.
  bool verifyHash({
    required String candidateHash,
    required String storedHash,
  }) {
    final candidateBytes = base64Url.decode(candidateHash);
    final storedBytes = base64Url.decode(storedHash);

    if (candidateBytes.length != storedBytes.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < candidateBytes.length; i++) {
      result |= candidateBytes[i] ^ storedBytes[i];
    }

    return result == 0;
  }
}
