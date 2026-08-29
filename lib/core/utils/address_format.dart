/// Приведение адреса от геокодера к виду, который можно показать человеку.
///
/// Внешние геокодеры (Яндекс, Nominatim, Photon) возвращают строку целиком:
/// «12, Байтик Баатыра, Бишкек, 720000, Кыргызстан». Почтовый индекс и страна
/// в подписи точки не нужны — заказ всегда внутри города.
library;

final RegExp _postalCodeOnly = RegExp(r'^\d{5,6}$');
final RegExp _postalCodeInside = RegExp(r'(?<!\d)\d{6}(?!\d)');

const Set<String> _countryNames = {
  'кыргызстан',
  'киргизия',
  'кыргызская республика',
  'казахстан',
  'россия',
  'российская федерация',
  'узбекистан',
  'таджикистан',
  'kyrgyzstan',
  'kazakhstan',
  'russia',
  'uzbekistan',
  'tajikistan',
};

bool _isNoisePart(String part) {
  final value = part.trim();
  if (value.isEmpty) return true;
  if (_postalCodeOnly.hasMatch(value)) return true;
  return _countryNames.contains(value.toLowerCase());
}

/// Убирает почтовый индекс и название страны из готовой строки адреса.
String formatReadableAddress(String? raw) {
  final source = raw?.trim() ?? '';
  if (source.isEmpty) return '';

  final parts = source
      .split(',')
      .where((part) => !_isNoisePart(part))
      .map((part) => part.replaceAll(_postalCodeInside, '').trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return source;

  // Попробуем привести части в более читаемый для пользователя порядок.
  // Ожидаемый приоритет: Проход (проход, проход №), Номер/код (начинается с цифры),
  // Базар/рынок (содержит слова рынок/базар), затем всё остальное.
  final passageRe = RegExp(r'\bпроход\b', caseSensitive: false, unicode: true);
  final bazarRe = RegExp(r'\b(рынок|базар)\b', caseSensitive: false, unicode: true);
  final startsWithDigit = RegExp(r'^\s*\d');

  final passageParts = <String>[];
  final numericParts = <String>[];
  final bazarParts = <String>[];
  final others = <String>[];

  for (final part in parts) {
    final p = part.trim();
    if (p.isEmpty) continue;
    if (passageRe.hasMatch(p)) {
      passageParts.add(p);
    } else if (startsWithDigit.hasMatch(p)) {
      numericParts.add(p);
    } else if (bazarRe.hasMatch(p)) {
      bazarParts.add(p);
    } else {
      others.add(p);
    }
  }

  final reordered = [...passageParts, ...numericParts, ...bazarParts, ...others];
  final cleaned = reordered.join(', ');
  // Если после чистки не осталось ничего осмысленного — лучше исходная строка,
  // чем пустая подпись под маркером.
  return cleaned.isEmpty ? source : cleaned;
}

/// Собирает адрес из отдельных компонентов геокодера, отбрасывая шум и дубли.
String joinAddressParts(Iterable<String?> parts) {
  final result = <String>[];
  for (final part in parts) {
    final value = part?.trim() ?? '';
    if (value.isEmpty || _isNoisePart(value)) continue;
    if (result.any((item) => item.toLowerCase() == value.toLowerCase())) {
      continue;
    }
    result.add(value);
  }
  return result.join(', ');
}
