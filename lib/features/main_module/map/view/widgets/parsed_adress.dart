final class ParsedAddress {
  final String fullAfterCity;
  final String? marketTitle;
  final String? detail;

  const ParsedAddress({
    required this.fullAfterCity,
    this.marketTitle,
    this.detail,
  });
}

ParsedAddress parseAddressForUi(String? address) {
  final clean = address?.trim() ?? '';
  if (clean.isEmpty) {
    return const ParsedAddress(fullAfterCity: '');
  }

  final parts = clean
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return const ParsedAddress(fullAfterCity: '');
  }

  String? marketTitle;
  for (final p in parts) {
    final lower = p.toLowerCase();
    if (lower.startsWith('рынок ') ||
        lower.contains('дордой') ||
        lower.contains('базар')) {
      marketTitle = p;
      break;
    }
  }

  return ParsedAddress(
    fullAfterCity: clean,
    marketTitle: marketTitle,
    detail: null,
  );
}
