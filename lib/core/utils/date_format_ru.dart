/// Форматирование даты и времени на русском без инициализации локали `intl`.
///
/// `DateFormat('d MMMM', 'ru')` требует `initializeDateFormatting()`, иначе
/// бросает исключение и код молча уходит в fallback. Здесь названия месяцев
/// заданы явно, поэтому результат предсказуем на всех платформах.
library;

const List<String> _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String _two(int value) => value.toString().padLeft(2, '0');

bool _isEmpty(DateTime date) => date.millisecondsSinceEpoch == 0;

/// `14 апреля, 23:57`. Год добавляется, если он отличается от текущего.
String formatOrderDate(DateTime date) {
  if (_isEmpty(date)) return '';

  final local = date.toLocal();
  final month = _monthsGenitive[local.month - 1];
  final year = local.year == DateTime.now().year ? '' : ' ${local.year}';

  return '${local.day} $month$year, ${_two(local.hour)}:${_two(local.minute)}';
}

/// `14.04.2026, 23:57` — для технических полей детального экрана.
String formatOrderDateTime(DateTime date) {
  if (_isEmpty(date)) return '—';

  final local = date.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year}, '
      '${_two(local.hour)}:${_two(local.minute)}';
}
