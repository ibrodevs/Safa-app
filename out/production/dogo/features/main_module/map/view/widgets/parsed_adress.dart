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
  if (address == null) {
    return const ParsedAddress(fullAfterCity: '');
  }

  final parts = address
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return const ParsedAddress(fullAfterCity: '');
  }

  if (parts.length <= 2) {
    final full = parts.join(', ');
    return ParsedAddress(
      fullAfterCity: full,
      marketTitle: parts.last,
      detail: null,
    );
  }

  final rest = parts.sublist(2);
  final fullAfterCity = rest.join(', ');

  var marketIdx = -1;
  for (var i = rest.length - 1; i >= 0; i--) {
    final lower = rest[i].toLowerCase();
    if (lower.startsWith('рынок ')) {
      marketIdx = i;
      break;
    }
  }

  String? marketTitle;
  String? detail;

  if (marketIdx != -1) {
    final raw = rest[marketIdx];
    const prefix = 'рынок ';
    var name = raw.startsWith(prefix) ? raw.substring(prefix.length).trim() : raw;
    if (name.isEmpty) {
      name = raw;
    }
    marketTitle = '$name базары';

    if (marketIdx + 1 < rest.length) {
      final detailParts = rest.sublist(marketIdx + 1);
      var d = detailParts.join(', ');
      if (d.isNotEmpty) {
        d = '$d контейнер';
      }
      detail = d;
    }
  } else {
    marketTitle = rest.first;
    if (rest.length > 1) {
      var d = rest.sublist(1).join(', ');
      if (d.isNotEmpty) {
        d = '$d контейнер';
      }
      detail = d;
    }
  }

  return ParsedAddress(
    fullAfterCity: fullAfterCity,
    marketTitle: marketTitle,
    detail: detail,
  );
}