import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/auth/data/services/credential_hash_service.dart';

void main() {
  late CredentialHashService service;

  setUp(() {
    service = const CredentialHashService();
  });

  group('CredentialHashService', () {
    test('generateSalt returns usable non-empty string of correct length', () {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt(16);

      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));
    });

    test('same credential and salt produce same hash', () {
      const password = 'my_secure_password';
      const salt = 'fixed_salt_for_test';

      final hash1 = service.hashCredential(credential: password, salt: salt);
      final hash2 = service.hashCredential(credential: password, salt: salt);

      expect(hash1, equals(hash2));
    });

    test('same credential and different salts produce different hashes', () {
      const password = 'my_secure_password';
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();

      final hash1 = service.hashCredential(credential: password, salt: salt1);
      final hash2 = service.hashCredential(credential: password, salt: salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('different credentials and same salt produce different hashes', () {
      const passwordA = 'passwordA';
      const passwordB = 'passwordB';
      const salt = 'fixed_salt_for_test';

      final hash1 = service.hashCredential(credential: passwordA, salt: salt);
      final hash2 = service.hashCredential(credential: passwordB, salt: salt);

      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyHash returns true for identical hashes', () {
      final hash = base64UrlEncode([1, 2, 3, 4, 5, 6]);
      expect(service.verifyHash(candidateHash: hash, storedHash: hash), isTrue);
    });

    test('verifyHash returns false for different hashes', () {
      final hash1 = base64UrlEncode([1, 2, 3, 4, 5, 6]);
      final hash2 = base64UrlEncode([6, 5, 4, 3, 2, 1]);
      expect(
          service.verifyHash(candidateHash: hash1, storedHash: hash2), isFalse);
    });
  });
}
