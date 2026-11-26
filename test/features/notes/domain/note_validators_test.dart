import 'package:agri_smart_guide/features/notes/domain/note_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteValidators.title', () {
    test('rejects missing, empty and whitespace-only titles', () {
      for (final value in [null, '', '   ', '\n\t']) {
        expect(NoteValidators.title(value), 'Unesite naslov bilješke.');
      }
    });

    test('accepts a title up to the maximum length after trimming', () {
      expect(NoteValidators.title('Gnojidba'), isNull);
      expect(
        NoteValidators.title('  ${'a' * NoteValidators.maxTitleLength}  '),
        isNull,
      );
    });

    test('rejects a title longer than the maximum length', () {
      expect(
        NoteValidators.title('a' * (NoteValidators.maxTitleLength + 1)),
        'Naslov može imati najviše ${NoteValidators.maxTitleLength} znakova.',
      );
    });
  });

  group('NoteValidators.content', () {
    test('rejects missing, empty and whitespace-only content', () {
      for (final value in [null, '', '   ', '\n\t']) {
        expect(NoteValidators.content(value), 'Unesite sadržaj bilješke.');
      }
    });

    test('accepts multi-line content up to the maximum length', () {
      expect(NoteValidators.content('Prvi red\nDrugi red'), isNull);
      expect(
        NoteValidators.content('a' * NoteValidators.maxContentLength),
        isNull,
      );
    });

    test('rejects content longer than the maximum length', () {
      expect(
        NoteValidators.content('a' * (NoteValidators.maxContentLength + 1)),
        'Sadržaj može imati najviše ${NoteValidators.maxContentLength} znakova.',
      );
    });
  });
}
