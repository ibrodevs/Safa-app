# UI Redesign Audit — Safa App (Flutter, `front/`)

Дата аудита: 2026-07-27
Ветка: `agent/redesign-mobile-ui` (от `main`, PR #1 `agent/fix-map-containers-cars` уже слит — коммит `c742cf4`)

Базовое состояние: `flutter analyze` → **45 issues, все уровня `info`** (ошибок и warnings нет).
Объём кода: 21 651 строк Dart в 122 файлах.

---

## 1. Перечень экранов и маршрутов

Роутер: `go_router`, `lib/core/router/app_router.dart`, единый `CustomTransitionPage` (slide 280/260 ms).
Навигация — два независимых `StatefulShellRoute.indexedStack`: клиентский шелл (4 таба) и шелл перевозчика (3 таба).

### Плоские маршруты

| Путь | Экран | Файл |
|---|---|---|
| `/` | Splash | `auth_module/splash/splash_screen.dart` |
| `/second_splash` | Onboarding | `auth_module/splash/second_splash_screen.dart` |
| `/select_role` | Выбор роли | `auth_module/select_role/select_role_screen.dart` |
| `/login` | Вход | `auth_module/login/login_screen.dart` |
| `/register-client` | Регистрация клиента | `auth_module/register/view/client_register_screens.dart` |
| `/register-carrier` | Регистрация перевозчика | `auth_module/register/view/carrier_register_screen.dart` |
| `/register/confirm` | Подтверждение селфи | `.../components/confirm_selfie_screen.dart` |
| `/register/confirm/whatsapp` | Код из WhatsApp | `.../components/confirm_whatsapp_code_screen.dart` |
| `/selfie-capture`, `/selfie-waiting` | Селфи-флоу | `.../components/selfie_*.dart` |
| `/privacy-policy` | Политика | `auth_module/register/view/privacy_policy_screen.dart` |
| `/history/detail` | Детали заказа (клиент) | `main_module/history/view/components/history_detail_data.dart` |
| `/history-carrier/detail` | Детали заказа (перевозчик) | `carrier_module/history/view/components/carrier_history_detail_data.dart` |
| `/profile/notifications` | Уведомления | `main_module/profile/view/components/profile_notifications_screen.dart` |
| `/profile/account` | Аккаунт | `.../profile_account_screen.dart` |
| `/profile/balance-history` | История баланса | `.../profile_balance_history_screen.dart` |
| `/profile/support` | Поддержка | `.../profile_support_screen.dart` |
| `/profile/topup` | Пополнение (перевозчик) | `carrier_module/profile/view/components/balance_top_up_screen.dart` |
| `/finik_pay` | Оплата Finik | `main_module/payments/view/finik_payment_screen.dart` |

### Шелл клиента (`BottomTabBar`)

`/home` → `/map?service=delivery|cars|amanat` → `/history` → `/profile`

### Шелл перевозчика (`BottomCarrierTabBar`)

`/home-carrier` → `/history-carrier` → `/profile-carrier`

### Модальные экраны (не в роутере)

`MapPickerScreen` (push через `MaterialPageRoute`), 3 bottom sheet выбора точки, `SearchingSheet`,
`OrderFulfillmentSheet`, `ShipmentPaymentSheet`, `OrderCompletedSheet`, `ImageSourceSheet`.

---

## 2. Найденные проблемы

### 2.1. Нет дизайн-системы — четыре конкурирующих источника правды о цвете

1. `lib/core/utils/app_colors.dart` — 30 констант, среди них **пять разных оранжевых**:
   `primary #FF8656`, `burntOrange #EA5E27`, `paywallAccent #FF7A00`, `accent #FF8A00`, `buttonColor #E47F26`.
   Плюс неиспользуемые `blue`, `deepPurple`, `red #FF0000`, `red2`.
2. Приватные копии тех же значений в 12+ файлах:
   `_accent = Color(0xFFFF8A00)` в `from_point_sheet`, `deliveri_point_sheet`, `intermediate_point_sheet`,
   `map_picker_screen`, `ref_suggest_field`, `add_adress_button`, `profile_screen`;
   `_accent = Color(0xFFE67E22)` в `bottom_tab_bar`, `history_screen`, `primary_button`, `login_screen`,
   `select_role_screen`. Кнопка «Войти» и активный таб — **разного оранжевого**.
3. Литералы прямо в `build`: `Color(0xFF8F97A3)`, `Color(0xFF9AA0A6)`, `Color(0xFF7A828D)`,
   `Color(0xFFB7BCC5)`, `Color(0xFF43C432)`, `Color(0xFF41C44B)`, `Color(0xFFF28C28)`, `Color(0xFF2E7D32)`.
   Только серых для вторичного текста — **шесть** оттенков.
4. `main.dart`: `ColorScheme.fromSeed(seedColor: Colors.orange)` — сгенерированная схема Material вообще
   не совпадает с фирменным цветом и почти нигде не используется, т.к. все виджеты задают цвет вручную.

### 2.2. Типографика

* `lib/core/utils/styles.dart` содержит всего 5 стилей и используется в 3 файлах; остальные ~100 файлов
  пишут `TextStyle` инлайн.
* **Несуществующие семейства шрифтов.** В `pubspec.yaml` объявлены `Gilroy`, `SFProText`, `SFProDisplay`.
  Код при этом ссылается на `'Inter'` (тема в `main.dart`), `'SF Pro Display'` и `'SF Pro'`
  (`small_card_widget`, `header_widget`, `tag_chip_widget`). Ни одного из этих трёх семейств в проекте нет —
  Flutter молча падает на системный шрифт. Итог: приложение рендерится тремя разными шрифтами
  в зависимости от экрана.
* Разнобой размеров: 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 24, 27, 28, 30 px — 15 значений.
* Разнобой насыщенности: w400…w900, причём `w900` используется как «заголовок» в 9 файлах,
  но реального 900 начертания в подключённых шрифтах нет (максимум 700).
* Опасные `height`: `cardTitleStyle` имеет `height: 0.2`, `tag_chip_widget` — `height: 0.778`.
  При `textScaleFactor` 1.2–1.4 такой line-height обрезает глифы.

### 2.3. Отступы и радиусы — случайные значения

* Отступы: 2, 4, 6, 8, 9.17, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 40, 56, 60 и «магические»
  `SizedBox(height: 200)` (profile), `240` (client_register), `405` (confirm_whatsapp),
  `SizedBox(height: 60)` внутри карточки главного экрана.
* Радиусы: 3, 4.89, 6, 8, 10, 12, 14, 16, 18, 20, 28 — 11 значений без системы.
  Поля ввода имеют радиус 8 (`app_text_field`), а кнопка под ними — 8, а карточка над ними — 16 или 20.
* Тени: 6 разных наборов `boxShadow`, включая тяжёлые (`elevation: 12`, `blurRadius: 60`).

### 2.4. Дублирование компонентов

| Дубликат | Файлы | Строк дублировано |
|---|---|---|
| Bottom sheet выбора точки | `from_point_sheet.dart`, `deliveri_point_sheet.dart`, `intermediate_point_sheet.dart` | ~1300 строк, различия только в заголовке и хинтах |
| Маркер контейнера | `map_screen.dart::_ContainerMarker`, `map_picker_screen.dart::_ContainerMarker` | 2 реализации, разные размеры/поведение |
| Индикатор загрузки контейнеров | `map_screen.dart::_ContainersButton`, `map_picker_screen.dart::_ContainersStatus` | 2 реализации |
| Аватар | `home/components/avatar_widget.dart::Avatar`, `profile_screen.dart::_Avatar` | 2 реализации (44 px и 76 px) |
| Карточка списка | `history_screen.dart::_HistoryCard`, `carrier_history_screen.dart` | 2 реализации |
| Основная кнопка | `core/widgets/primary_button.dart` + инлайновые `ElevatedButton` в 11 файлах | у каждой свой цвет/радиус/высота |
| Маппинг статуса → текст | `history_screen.dart::_mapStatus`, `history_detail_data.dart::_mapStatus` | идентичные копии |
| Строка «стоп → стоп → стоп» | `search_sheet.dart`, `order_fulfillment_sheet.dart`, `history_detail_data.dart` | 3 разных визуальных языка для одного и того же маршрута |

### 2.5. Жёстко заданные размеры и риск `RenderFlex overflow`

| Место | Проблема |
|---|---|
| `big_card_widget.dart:87` | `SizedBox(width: 150, height: 150)` под картинку + `Transform.scale(1.20)`. При ширине 320 px на текст остаётся 320−48−150−12 = 110 px → `Row` переполняется. |
| `big_card_widget.dart:78` | Фиксированный `SizedBox(height: 60)` как «распорка» вместо `Expanded` — при `textScale` 1.4 колонка выше картинки. |
| `select_role_screen.dart:139` | `_avatarBoxSize = 110` в `Row` рядом с `Expanded` текстом — на 320 px тесно. |
| `profile_screen.dart:157` | `SizedBox(height: 200)` — «костыль» под нижнюю навигацию. |
| `client_register_screens.dart:212` | `SizedBox(height: 240)` — то же. |
| `confirm_whatsapp_code_screen.dart:161` | `SizedBox(height: 405)` — то же; на iPhone SE это пустой скролл на пол-экрана. |
| `order_fulfillment_sheet.dart:127` | `SizedBox(width: 110, height: 40)` внутри `Row` без `Flexible`. |
| `_TrailingStatus` | `width: 110` фиксировано, текст «Забрали груз» при `textScale` 1.4 не влезает. |
| `map_screen.dart:830` | `Marker(width: 220, height: 140)` + `Transform.translate(offset: (0,-55))` для «здесь»-бабла — при длинном адресе текст обрезается. |
| `tag_chip_widget.dart` | `height: 26` + `FittedBox(scaleDown)` — при увеличенном системном шрифте текст сжимается в нечитаемый. |
| `input_tile.dart` | `height: 52` жёстко; текст `maxLines: 1` — длинный адрес контейнера просто исчезает. |

### 2.6. Клавиатура

* `login_screen.dart`, `client_register_screens.dart`, `carrier_register_screen.dart`,
  `select_role_screen.dart`, `confirm_whatsapp_code_screen.dart` — все с
  `resizeToAvoidBottomInset: false` и ручной компенсацией `MediaQuery.viewInsetsOf(context).bottom`
  внутри `padding`. Это работает случайно: активное поле не скроллится к себе, кнопка уезжает под
  клавиатуру, а `RegisterDotsIndicator` в `Positioned(bottom: bottomPadding)` остаётся поверх клавиатуры.
* `login_screen` не имеет обработчика тапа вне поля → фокус не снимается.
* `client_register_screens` не снимает фокус после отправки.
* Bottom sheets выбора точки учитывают `viewInsets.bottom`, но содержимое обёрнуто в
  `SingleChildScrollView` без `ConstrainedBox`, а сам sheet — в `Padding(top: 60)`:
  при открытой клавиатуре и раскрытом списке подсказок `RefSuggestField` (216 px) содержимое
  выходит за экран.
* `ref_suggest_field.dart` рисует список подсказок как обычный `Column`-сиблинг **внутри** формы,
  а не в `Overlay`. Из-за этого при открытии подсказок весь контент под полем прыгает вниз.

### 2.7. Неправильное использование `MediaQuery`

* `select_role_screen.dart:20`, `client_register_screens.dart:85`, `confirm_whatsapp_code_screen.dart:75` —
  `MediaQuery.of(context).padding.bottom` вместо `MediaQuery.viewPaddingOf`/`SafeArea`,
  что заставляет весь виджет перестраиваться на любое изменение метрик.
* Нигде нет `LayoutBuilder`, нет ограничения максимальной ширины контента — на планшете/600 px
  формы растягиваются на всю ширину.
* Нет ни одного использования `Wrap` — все ряды чипов и статусов жёсткие `Row`.

### 2.8. Состояния загрузки / пустоты / ошибки

* `history_screen`: загрузка — голый `Center(child: CircularProgressIndicator())` на весь экран;
  пусто — одна серая строка «У вас пока нет посылок» без иконки и действия;
  ошибка — `Text(state.error!, style: TextStyle(color: Colors.red))`.
* `shipments_history_provider.dart:45` — `_error = e.toString()`. Пользователю показывается
  `ApiException(500, <html>…)` или `DioException [connection error]`. Прямое нарушение требования §18.
* `home_screen`, `profile_screen` — ошибка печатается красным текстом в конце скролла, где её не видно.
* Нет ни одного `retry`-действия ни на одном экране.
* Ошибки полей формы показываются только через `Snackbar` (`login_screen`, `client_register_screens`),
  под самим полем ошибки нет.

### 2.9. Доступность

* Область нажатия `PasswordEye` — 14 px иконка + 8 px padding = 30 px (< 44 px).
* `SheetBackPill` — 8 px вертикального padding, итого ~37 px.
* `_ContainerMarker` в `map_screen` вообще не кликабелен (нет `GestureDetector`), только `Tooltip` —
  выбрать контейнер с главной карты нельзя, только через `MapPickerScreen`.
* Статусы заказа отличаются **только цветом текста** (`_statusGreen` для всех статусов, включая
  «Отменено») — и цвет один и тот же для успеха и отмены, т.е. статус фактически не читается.
* `Semantics` есть ровно в одном месте (`map_picker_screen::_ContainerMarker`).
* `height: 0.2` и `height: 0.778` в текстовых стилях гарантируют обрезку при увеличенном системном шрифте.

### 2.10. Производительность

Что уже сделано хорошо и должно быть сохранено:
* debounce загрузки контейнеров (450 ms в `map_screen`, 350 ms в `map_picker_screen`);
* `_containersRequestSerial` для отбрасывания устаревших ответов;
* `map_picker_screen` сохраняет последние успешно загруженные маркеры при сетевой ошибке;
* `_routeSignature` предотвращает перепостроение маршрута OSRM;
* `dispose` корректно закрывает таймеры и стримы.

Что надо исправить:
* `map_screen.dart:187` — `_refreshVisibleContainers` делает `setState` три раза за вызов
  (`loading=true`, `_visibleContainers`, `loading=false`), каждый перестраивает **весь** `Stack` с картой.
* `map_screen.dart:209` — при ошибке загрузки `_visibleContainers = const []`, т.е. маркеры
  **пропадают** при кратковременной сети (в `map_picker_screen` это уже исправлено — надо перенести).
* `map_screen.dart:798-871` — весь список `Marker` и `Polygon` пересоздаётся внутри `build`
  при каждом `setState`, включая жест панорамирования.
* `map_screen.dart:172` — `await Future.delayed(1100 ms)` между сегментами OSRM: маршрут из 4 точек
  строится 3.3 секунды без индикации.
* `map_picker_screen.dart:348` — `setState(() {})` на каждый символ в поле поиска только чтобы
  показать кнопку «очистить».
* `map_screen.dart` — один файл на 1193 строки, `carrier_home_screen.dart` — 2168 строк.

### 2.11. Различия между «Доставка», «Тачки» и «Аманат»

Сейчас **все три раздела — это один и тот же экран** `OrderMapScreen`, отличающийся только
`serviceType` из query-параметра, который уходит в `service_type` при создании заказа.
Визуальных различий нет вообще, но нет и признаков сценария:

* заголовок экрана не показывает, какой сервис выбран;
* «Тачки» (маршрут с несколькими точками) не имеют ни списка промежуточных точек, ни возможности
  их удалить или переупорядочить — точка добавляется в `_intermediatePoints` и исчезает из UI навсегда;
* кнопка добавления точки называется «+ Адрес» и покрашена в серый (`AppColors.grey`) на белом,
  хотя должна быть акцентной;
* «Аманат» не имеет поля описания посылки, хотя API `POST delivery/shipments/` **уже принимает**
  `description` (сейчас всегда отправляется пустая строка);
* на главном экране «Доставка» и «Тачки» — `BigFeatureCard` (картинка справа), «Аманат» —
  `SmallFeatureCard` (картинка сверху). Три сервиса выглядят как два разных продукта.

### 2.12. Прочее

* `history_detail_data.dart:174` — в исходнике буквально строка
  `// ignore: unused_local_variable\r\n        final priceText = ...` — экранированный `\r\n`
  попал в код, из-за чего вся строка закомментирована и `priceText` не используется.
* `map_screen.dart` не имеет кнопки «назад» и кнопки «моя геолокация».
* `add_adress_button.dart` импортирует `AppColors`, но объявляет свои приватные `_accent`/`_tileBorder`.
* `profile_screen` не содержит выхода из аккаунта вообще, хотя `LogoutService` реализован.
* `bottom_tab_bar.dart` — активная иконка «Главное» использует ассет `ic_home_grey.svg`,
  а неактивная — `ic_home.svg` (перепутаны).

---

## 3. План рефакторинга

### Этап 1. Дизайн-система (`lib/core/design/`)

Единый источник правды. Существующий `lib/core/utils/app_colors.dart` **не удаляется** (его импортируют
40 файлов) — он превращается в `export` нового файла, а `AppColors` получает новые токены и
legacy-алиасы, указывающие на новые значения. `lib/core/utils/styles.dart` — так же (`AppTextStyles`
сохраняет имена, но получает корректные `height` и существующее семейство шрифтов).

* `app_colors.dart` — палитра из ТЗ §5 + семантические токены + legacy-алиасы.
* `app_typography.dart` — 11 стилей на базе `SFProText`/`SFProDisplay` (реально подключённые семейства).
* `app_spacing.dart` — сетка 4/8/12/16/20/24/32 + адаптивные горизонтальные отступы.
* `app_radius.dart` — 12/14/16/20/24/28 + `full`.
* `app_shadows.dart` — 3 мягких уровня (`card`, `raised`, `sheet`).
* `app_breakpoints.dart` — пороги 360/430/600 px, `maxContentWidth = 560`.
* `app_icons.dart` — константы путей к SVG (сейчас 23 ассета разбросаны строками по коду).
* `app_theme.dart` — `ThemeData` MD3 с настоящей `ColorScheme` от `#FF8A00`, темами полей,
  кнопок, `BottomNavigationBar`, `AppBar`, `SnackBar`.

### Этап 2. Библиотека компонентов (`lib/core/widgets/`)

Создаются компоненты из ТЗ §7. `AppTextField` и `PrimaryButton` не удаляются, а расширяются
совместимым по API суперсетом, чтобы 11 существующих вызовов продолжали работать.

### Этап 3. Единый каркас сервиса

* `ServiceConfig` — описание сервиса (`delivery` / `cars` / `amanat`): заголовок, подзаголовок,
  иконка, оттенок, разрешены ли промежуточные точки, лимит остановок, тексты кнопок.
  `service_type` берётся отсюда и уходит в API без изменений.
* `RouteBuilder` — вертикальный маршрут с номерами точек, «+ Добавить остановку»,
  `ReorderableListView` для промежуточных, удаление только промежуточных.
* `PointPickerSheet` — **один** sheet вместо трёх, режим (`from` / `to` / `intermediate`) как параметр.
* `OrderSummarySheet` — итоговая карточка перед созданием заказа (маршрут, число точек, сервис,
  стоимость из существующего `POST delivery/shipments/quote/`, предупреждение о недостатке данных).

### Этап 4. Экраны

Auth → Home → Map/Order → Orders list → Order detail → Profile → Bottom nav.

### Этап 5. Состояния и ошибки

* `friendly_error.dart` — маппер `ApiException`/`DioException`/`SocketException` → текст для человека,
  включая обязательную формулировку офлайна из ТЗ §18.
* `ShipmentsHistoryProvider._error` переводится на этот маппер (логика запросов не меняется).

### Этап 6. Тесты

Widget-тесты компонентов + матрица размеров 320/360/390/430/600 с проверкой отсутствия
исключений и overflow.

---

## 4. Создаваемые компоненты

### Дизайн-система
`AppColors` (переработан), `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`,
`AppBreakpoints`, `AppIcons`, `AppTheme`, `AppResponsive`

### Общие компоненты (ТЗ §7)
`AppPrimaryButton`, `AppSecondaryButton`, `AppTextButton`, `AppIconButton`,
`AppTextField`, `AppPasswordField`, `AppSearchField`,
`AppCard`, `AppSectionHeader`, `AppServiceCard`, `AppOrderCard`, `AppStatusBadge`,
`AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppSkeleton`,
`AppBottomSheet` (+ `showAppBottomSheet`), `AppConfirmDialog`, `AppAvatar`, `AppListTile`,
`AppMapActionButton`, `AppAddressField`, `AppRoutePointTile`, `AppScreenScaffold`

### Сервисный каркас
`ServiceConfig`, `ServiceOrderPanel`, `RouteBuilder`, `PointPickerSheet`, `OrderSummarySheet`,
`ContainerMapMarker`, `ContainersStatusChip`

### Утилиты
`friendlyErrorMessage()`, `ShipmentStatusView` (статус → текст + цвет + иконка, вместо двух копий `_mapStatus`)

---

## 5. Удаляемые и заменяемые компоненты

| Компонент | Судьба |
|---|---|
| `map/view/components/from_point_sheet.dart` | **удаляется** → `PointPickerSheet(mode: from)` |
| `map/view/components/deliveri_point_sheet.dart` | **удаляется** → `PointPickerSheet(mode: destination)` |
| `map/view/components/intermediate_point_sheet.dart` | **удаляется** → `PointPickerSheet(mode: intermediate)` |
| `map/view/widgets/add_adress_button.dart` | **удаляется** → `AppSecondaryButton` в `RouteBuilder` |
| `map/view/widgets/input_tile.dart` | **удаляется** → `AppAddressField` |
| `map/view/widgets/sheet_back_pill.dart` | **удаляется** → drag handle + close в `AppBottomSheet` |
| `home/components/big_card_widget.dart` | **удаляется** → `AppServiceCard` |
| `home/components/small_card_widget.dart` | **удаляется** → `AppServiceCard` |
| `home/components/tag_chip_widget.dart` | **удаляется** → `AppStatusBadge` |
| `home/components/avatar_widget.dart` | **удаляется** → `AppAvatar` |
| `home/components/header_widget.dart` | **удаляется** → `HomeHeader` (новый, с уведомлениями и профилем) |
| `core/widgets/shadow_field.dart` | **удаляется** → тень внутри `AppTextField` |
| `core/widgets/eye_password.dart` | **удаляется** → `AppPasswordField` (область нажатия 44 px) |
| `core/widgets/primary_button.dart` | сохраняется как тонкая обёртка над `AppPrimaryButton` (11 мест вызова) |
| `core/widgets/app_text_field.dart` | переносится в `core/widgets/fields/app_text_field.dart`, API-суперсет |
| `map_screen.dart::_ContainerMarker` / `_ContainersButton` | **удаляются** → `ContainerMapMarker` / `ContainersStatusChip` |
| `map_picker_screen.dart::_ContainerMarker` / `_ContainersStatus` | **удаляются** → те же общие |
| `history_screen.dart::_HistoryCard` / `_EmptyHistoryPlaceholder` / `_HistoryChip` | **удаляются** → `AppOrderCard` / `AppEmptyState` |
| `profile_screen.dart::_Avatar` / `_ProfileTile` | **удаляются** → `AppAvatar` / `AppListTile` |
| `history_screen.dart::_mapStatus`, `history_detail_data.dart::_mapStatus` | **удаляются** → `ShipmentStatusView` |
| `core/utils/app_colors.dart` | сохраняется как `export` нового `core/design/app_colors.dart` |
| `core/utils/styles.dart` | сохраняется, `AppTextStyles` перенаправлен на `AppTypography` |

---

## 6. Что запрещено ломать (проверочный список)

Ни один из пунктов ниже не затрагивается редизайном — меняется только представление.

* `AuthProvider` (login / register / sendWhatsappCode / verifyCodeAndLogin), JWT в
  `SecureStorageService`, `ApiService.setBearer`, восстановление сессии в `SplashScreen`.
* Разделение ролей: `provider.role`, редиректы `/home` vs `/home-carrier`, оба `StatefulShellRoute`.
* Все маршруты `go_router` и их пути — сохраняются один в один.
* `POST delivery/shipments/` — поля `title`, `service_type`, `description`, `stops`, `return_to_start`.
* `DeliveryPoint.toStopJson()` — формат стопа (`title`, `lat`, `lon`, `bazar`, `passage`, `container`, `q`)
  и логика восстановления метаданных контейнера из `subtitle` (покрыта существующими тестами).
* `DeliveryRefsRepository` — `searchBazars` / `searchPassages` / `searchContainers` /
  `loadContainersInBounds` (загрузка по видимой области карты сохраняется, включая debounce и serial).
* `ActiveShipmentProvider`, поллинг статуса раз в 5 с, `patchShipmentStatus`, `ShipmentPaymentSheet`,
  флоу Finik.
* `flutter_map` + CartoDB tiles, OSRM-маршрутизация, `geolocator` (включая обработку отказа
  в разрешении и выключенного GPS).
* `service_type` = `delivery` / `cars` / `amanat`, передача из query-параметра `/map?service=`.
* Модуль перевозчика (`carrier_module`) — приводится к общей палитре и компонентам,
  бизнес-логика и экраны не переписываются.

**Backend не изменяется.** Все новые элементы интерфейса используют уже существующие поля API:
описание посылки для «Аманат» — существующее поле `description`; стоимость в итоговой карточке —
существующий `POST delivery/shipments/quote/`.
