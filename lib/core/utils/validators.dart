/// Centralized form input validators for Vital Track.
class Validators {
  // RFC 5322 compatible email pattern
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
  );

  // Password criteria regexes
  static final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegExp = RegExp(r'[a-z]');
  // Matches any digit or common symbol / non-alphanumeric character
  static final RegExp _numberOrSymbolRegExp = RegExp(
    r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/~`\x27;]',
  );

  /// Validates full name on registration
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (!trimmed.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Full name must contain valid letters';
    }
    return null;
  }

  /// Validates email format for login and registration
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g. name@example.com)';
    }
    return null;
  }

  // --- Password Criteria Checks (used for real-time UI feedback) ---
  static bool hasMinLength(String value, [int min = 6]) => value.length >= min;
  static bool hasCapitalLetter(String value) => _uppercaseRegExp.hasMatch(value);
  static bool hasSmallLetter(String value) => _lowercaseRegExp.hasMatch(value);
  static bool hasNumberOrSymbol(String value) =>
      _numberOrSymbolRegExp.hasMatch(value) ||
      value.contains(RegExp(r'[^a-zA-Z\s]'));

  /// Validates registration password:
  /// Requires:
  /// - Minimum 6 characters
  /// - At least 1 capital letter (A-Z)
  /// - At least 1 small letter (a-z)
  /// - At least 1 number or symbol
  static String? validateRegistrationPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!hasMinLength(value, 6)) {
      return 'Password must be at least 6 characters long';
    }
    if (!hasCapitalLetter(value)) {
      return 'Password must contain at least 1 capital letter (A-Z)';
    }
    if (!hasSmallLetter(value)) {
      return 'Password must contain at least 1 small letter (a-z)';
    }
    if (!hasNumberOrSymbol(value)) {
      return 'Password must contain at least 1 number or symbol';
    }
    return null;
  }

  /// Validates login password
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates confirmation password against the original password
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
