abstract final class NoteValidators {
  static const int maxTitleLength = 100;
  static const int maxContentLength = 5000;

  static String? title(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Unesite naslov bilješke.';
    if (title.length > maxTitleLength) {
      return 'Naslov može imati najviše $maxTitleLength znakova.';
    }
    return null;
  }

  static String? content(String? value) {
    final content = value?.trim() ?? '';
    if (content.isEmpty) return 'Unesite sadržaj bilješke.';
    if (content.length > maxContentLength) {
      return 'Sadržaj može imati najviše $maxContentLength znakova.';
    }
    return null;
  }
}
