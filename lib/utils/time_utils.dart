const Duration _turkeyOffset = Duration(hours: 3);

bool _hasTimeZoneInfo(String raw) {
  return RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw);
}

DateTime nowInTurkey() {
  return DateTime.now().toUtc().add(_turkeyOffset);
}

DateTime? parseServerDateToTurkey(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.add(_turkeyOffset);
  }
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final utc = _hasTimeZoneInfo(raw)
      ? parsed.toUtc()
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.add(_turkeyOffset);
}
