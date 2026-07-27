/// Форматирование кыргызского номера телефона для отображения.
///
/// Вынесено из `profile_screen`, где было приватным методом виджета,
/// чтобы одинаковый формат использовался и в профиле клиента,
/// и в профиле перевозчика.
library;

/// Приводит любой ввод к виду `+996 700 00-00-00`.
///
/// Если номер не распознан, возвращается исходная строка с `+`.
/// Формат отправки на backend этой функцией не затрагивается.
String formatKgPhone(String? input) {
  if (input == null) return '—';

  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '—';

  if (digits.startsWith('0') && digits.length == 10) {
    digits = digits.substring(1);
  }

  if (digits.length == 9) {
    digits = '996$digits';
  }

  if (digits.length == 12 && digits.startsWith('996')) {
    final operator = digits.substring(3, 6);
    final a = digits.substring(6, 8);
    final b = digits.substring(8, 10);
    final c = digits.substring(10, 12);
    return '+996 $operator $a-$b-$c';
  }

  final trimmed = input.trim();
  return trimmed.startsWith('+') ? trimmed : '+$digits';
}
