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
  'китай',
  'kyrgyzstan',
  'kazakhstan',
  'russia',
  'uzbekistan',
  'tajikistan',
  'china',
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

  final cleaned = parts.join(', ');
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
