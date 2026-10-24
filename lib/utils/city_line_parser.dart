/// Result of parsing the single "City, State, Pincode" form field.
class ParsedCityLine {
  final String city;
  final String state;
  final String pincode; // '' when no 6-digit pincode was found
  const ParsedCityLine(this.city, this.state, this.pincode);
}

ParsedCityLine parseCityLine(String raw) {
  final pinMatch = RegExp(r'(?<!\d)\d{6}(?!\d)').firstMatch(raw);
  final pincode = pinMatch?.group(0) ?? '';
  final rest = pinMatch == null
      ? raw
      : raw.replaceRange(pinMatch.start, pinMatch.end, '');
  final parts = rest
      .split(RegExp(r'\s*,\s*|\s+-\s+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final city = parts.isNotEmpty ? parts[0] : '';
  final state = parts.length > 1 ? parts[1] : '';
  return ParsedCityLine(city, state, pincode);
}
