/// Coerce a JSON-decoded value (which may be int, double, String, or null)
/// into an int. Used heavily on creator/brand screens where backend payloads
/// occasionally serialize numeric fields as strings — a raw `> 0` comparison
/// against a String throws at runtime.
int toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double toDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

/// True only when [v] is a non-empty string. Guards against `Image.network('')`,
/// which throws in Flutter.
bool isNonEmptyString(dynamic v) => v is String && v.isNotEmpty;
