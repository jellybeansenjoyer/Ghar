/// Input validators for form fields across the Ghar app.
class Validators {
  Validators._();

  /// Validates a phone number (E.164 format or 10+ digits).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+')) {
      if (cleaned.length < 10 || cleaned.length > 15) {
        return 'Enter a valid phone number';
      }
    } else {
      if (cleaned.length < 10) {
        return 'Enter a valid phone number';
      }
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  /// Validates a name field.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }
    return null;
  }

  /// Validates an OTP code (6 digits).
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  /// Validates a family name.
  static String? familyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Family name is required';
    }
    if (value.trim().length < 2) {
      return 'Family name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Family name must be less than 50 characters';
    }
    return null;
  }

  /// Validates an address field (optional but with length limit).
  static String? address(String? value) {
    if (value != null && value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }
    return null;
  }

  /// Validates a chat message.
  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.trim().length > 500) {
      return 'Message must be less than 500 characters';
    }
    return null;
  }
}
