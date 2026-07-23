
// ignore_for_file: curly_braces_in_flow_control_structures

abstract final class TenantValidators {
  // Matches a name that contains only letters (Unicode) and spaces.
  static final _nameRegExp = RegExp(r"^[\p{L} ]+$", unicode: true);

  // Strictly 10 numeric digits.
  static final _phone10RegExp = RegExp(r'^\d{10}$');

  // Basic RFC-5322–inspired email pattern.
  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates the tenant's full name.
  static String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter tenant name.';
    if (v.length < 3) return 'Name must be at least 3 characters.';
    if (v.length > 60) return 'Name must be 60 characters or fewer.';
    if (!_nameRegExp.hasMatch(v))
      return 'Name may contain letters and spaces only.';
    return null;
  }

  /// Validates the primary phone number (required, exactly 10 digits).
  static String? validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter phone number.';
    if (!_phone10RegExp.hasMatch(v))
      return 'Enter a valid 10-digit phone number.';
    return null;
  }

  /// Validates an email address (optional — only checked when non-empty).
  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!_emailRegExp.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  /// Validates the address field (optional, max 300 chars).
  static String? validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (v.length > 300) return 'Address must be 300 characters or fewer.';
    return null;
  }

  /// Validates the emergency contact phone (optional, 10 digits when provided).
  static String? validateEmergencyPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!_phone10RegExp.hasMatch(v))
      return 'Enter a valid 10-digit phone number.';
    return null;
  }
}
