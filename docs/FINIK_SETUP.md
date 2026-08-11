# Finik во Flutter

Полная инструкция, включая backend callback и Chatflow, находится в
`DoGO/docs/FINIK_CHATFLOW_SETUP.md` соседнего backend-репозитория.

Для Flutter нужен только выданный Finik **API client key**. Account ID приходит
с backend и не задаётся в приложении.

Запуск beta:

```bash
flutter run \
  --dart-define=DOGO_API_BASE_URL=https://api.example.com/api/ \
  --dart-define=FINIK_API_KEY=your-flutter-api-client-key \
  --dart-define=FINIK_BETA=true
```

Production-сборка:

```bash
flutter build apk --release \
  --dart-define=DOGO_API_BASE_URL=https://api.example.com/api/ \
  --dart-define=FINIK_API_KEY=your-production-api-client-key \
  --dart-define=FINIK_BETA=false
```

Опционально название платежа задаётся через
`--dart-define='FINIK_ITEM_NAME_EN=Safa delivery payment'`.

Не добавляйте реальный ключ в Dart-файлы, assets или git. В CI храните его как
masked/protected secret. Beta key, beta-режим и backend account ID всегда должны
относиться к одному окружению Finik.
