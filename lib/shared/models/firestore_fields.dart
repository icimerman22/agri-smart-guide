/// Reads a schema field without silently replacing malformed required data.
T? readField<T>(
  String key,
  Map<String, dynamic> data,
  T Function(dynamic) convert, {
  bool optional = false,
}) {
  final value = data[key];
  if (value == null) {
    if (optional) return null;
    throw FormatException('Missing required field: $key');
  }
  try {
    return convert(value);
  } on TypeError {
    throw FormatException('Invalid type for field: $key');
  } on ArgumentError {
    throw FormatException('Invalid value for field: $key');
  }
}

Map<String, dynamic> freezeMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key, _freeze(item))),
    );

dynamic _freeze(dynamic value) {
  if (value is Map) return freezeMap(Map<String, dynamic>.from(value));
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freeze));
  return value;
}
