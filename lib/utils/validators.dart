class Validators {
  const Validators._();

  static String? requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi.';
    }
    return null;
  }

  static String? requiredSelection(Object? value, String fieldName) {
    if (value == null) {
      return '$fieldName wajib dipilih.';
    }
    return null;
  }

  static String? latitude(String? value) {
    final requiredError = requiredText(value, 'Latitude');
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < -90 || parsed > 90) {
      return 'Latitude harus berada di antara -90 dan 90.';
    }
    return null;
  }

  static String? longitude(String? value) {
    final requiredError = requiredText(value, 'Longitude');
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < -180 || parsed > 180) {
      return 'Longitude harus berada di antara -180 dan 180.';
    }
    return null;
  }
}
