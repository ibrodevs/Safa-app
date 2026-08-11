final class FinikConfig {
  const FinikConfig._();

  static const apiKey = String.fromEnvironment('FINIK_API_KEY');

  static const isBeta = bool.fromEnvironment('FINIK_BETA', defaultValue: false);

  static const itemNameEn = String.fromEnvironment(
    'FINIK_ITEM_NAME_EN',
    defaultValue: 'Safa delivery payment',
  );
}
