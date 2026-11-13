/// Validation rules for the profile form.
///
/// Each method returns a Croatian error message, or `null` when the value is
/// valid, so it can be passed directly as a form field `validator`.
class ProfileValidators {
  ProfileValidators._();

  static const int maxNameLength = 50;
  static const int maxFarmNameLength = 100;

  // Letters (including č, ć, đ, š, ž), spaces, hyphens and apostrophes.
  static final RegExp _namePattern = RegExp(
    r"^[\p{L}][\p{L} '\-]*$",
    unicode: true,
  );

  static String? firstName(String? value) =>
      _personName(value, missing: 'Molimo unesite ime.', label: 'Ime');

  static String? lastName(String? value) =>
      _personName(value, missing: 'Molimo unesite prezime.', label: 'Prezime');

  /// Optional: a hobby gardener may not have a registered farm.
  static String? farmName(String? value) {
    final farmName = value?.trim() ?? '';
    if (farmName.length > maxFarmNameLength) {
      return 'Naziv gospodarstva može imati najviše $maxFarmNameLength znakova.';
    }
    return null;
  }

  static String? _personName(
    String? value, {
    required String missing,
    required String label,
  }) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return missing;
    if (name.length > maxNameLength) {
      return '$label može imati najviše $maxNameLength znakova.';
    }
    if (!_namePattern.hasMatch(name)) {
      return '$label smije sadržavati samo slova, razmake, crticu i apostrof.';
    }
    return null;
  }
}
