/// Validation utilities for forms and user input
class ValidationUtils {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Format email invalide';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Mot de passe doit contenir min 6 caractères';
    }

    // Check for at least one uppercase letter, one lowercase, one number
    final hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));

    if (!hasUpperCase || !hasLowerCase || !hasDigit) {
      return 'Mot de passe doit contenir majuscule, minuscule et chiffre';
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nom est requis';
    }

    if (value.length < 2) {
      return 'Nom doit contenir min 2 caractères';
    }

    if (value.length > 100) {
      return 'Nom doit contenir max 100 caractères';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Zàâäçéèêëïîôùûüœæ\s'-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Nom contient des caractères non valides';
    }

    return null;
  }

  /// Validate level
  static String? validateLevel(int? value) {
    if (value == null) {
      return 'Niveau est requis';
    }

    if (value < 1 || value > 10) {
      return 'Niveau doit être entre 1 et 10';
    }

    return null;
  }

  /// Validate team name
  static String? validateTeamName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nom d\'équipe est requis';
    }

    if (value.length < 2) {
      return 'Nom d\'équipe doit contenir min 2 caractères';
    }

    if (value.length > 50) {
      return 'Nom d\'équipe doit contenir max 50 caractères';
    }

    return null;
  }

  /// Validate not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Validate passwords match
  static String? validatePasswordsMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Validate file size (in MB)
  static String? validateFileSize(int fileSizeInBytes, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    if (fileSizeInBytes > maxSizeInBytes) {
      return 'Fichier trop volumineux (max $maxSizeInMB MB)';
    }
    return null;
  }

  /// Get error message for form fields
  static String getFieldErrorMessage(String fieldType, {String? customMessage}) {
    if (customMessage != null) return customMessage;

    final messages = {
      'email': 'Email invalide',
      'password': 'Mot de passe invalide',
      'name': 'Nom invalide',
      'level': 'Niveau invalide',
      'team': 'Équipe invalide',
    };

    return messages[fieldType] ?? 'Valeur invalide';
  }
}
