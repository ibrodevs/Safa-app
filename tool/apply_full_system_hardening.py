from __future__ import annotations

from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one match in {path}, found {count}: {old[:120]!r}")
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


# Safe production fallback and self-profile contract.
replace_once(
    "lib/data/network/api_service.dart",
    "    defaultValue: 'http://46.101.255.131:8001/api/',\n",
    "    defaultValue: 'https://safabackend21.pythonanywhere.com/api/',\n",
)
replace_once(
    "lib/data/network/api_service.dart",
    "      final path = (id != null) ? 'users/profile/$id/' : 'users/profile/';\n\n      final resp = await _dio.patch(path, data: data);\n",
    "      // Профиль редактируется только через self-endpoint. URL с ID на backend\n"
    "      // предназначен исключительно для чтения и отклоняет PATCH.\n"
    "      final resp = await _dio.patch('users/profile/', data: data);\n",
)

# Existing accounts must be sent to login, not into a broken OTP registration flow.
replace_once(
    "lib/features/auth_module/register/provider/auth_provider.dart",
    '''      final alreadyExists =
          e.statusCode == 400 &&
          e.message.toLowerCase().contains('уже существует');
      if (alreadyExists) {
        try {
          await _repo.login(phoneNumber: phoneNumber, password: password);
          _pendingPhone = phoneNumber;
          _loggedIn = true;
          _error = null;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_phone', phoneNumber);

          _loading = false;
          notifyListeners();
          return true;
        } on ApiException catch (e2) {
          _loading = false;
          _error = e2.message;
          notifyListeners();
          return false;
        }
      }
''',
    '''      final alreadyExists =
          e.statusCode == 400 &&
          (e.message.toLowerCase().contains('уже существует') ||
              e.message.toLowerCase().contains('уже зарегистрирован'));
      if (alreadyExists) {
        _loading = false;
        _error = 'Аккаунт с этим номером уже существует. Войдите через экран авторизации.';
        notifyListeners();
        return false;
      }
''',
)

# History tabs need all statuses, not the completed-only /history endpoint.
Path("lib/features/main_module/history/data/repo/shipments_history_repo.dart").write_text(
    '''import '../../../../../data/network/api_service.dart';
import '../model/shipment_history_models.dart';

class ShipmentsHistoryRepository {
  final ApiService _api;

  ShipmentsHistoryRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ShipmentHistoryPage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    final json = await _api.getShipments(page: page, pageSize: pageSize);
    return ShipmentHistoryPage.fromJson(json);
  }
}
''',
    encoding="utf-8",
)

# FCM registration follows the actual token, and app:// links are converted to GoRouter routes.
Path("lib/data/notifications/service/push_service.dart").write_text(
    '''import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../data/network/api_service.dart';
import 'notification_service.dart';

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  bool _inited = false;
  String? _lastToken;

  Future<void> init() async {
    if (_inited) return;

    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _lastToken = await _fm.getToken();

    FirebaseMessaging.onMessage.listen((msg) async {
      await NotificationService.instance.showFromMessage(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _routeFromData(msg.data);
    });
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _routeFromData(initial.data);
    }

    _fm.onTokenRefresh.listen((token) async {
      _lastToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_registered_token_client');
      await prefs.remove('fcm_registered_token_carrier');
    });
    _inited = true;
  }

  void _routeFromData(Map<String, dynamic> data) {
    final app = data['app']?.toString().toLowerCase();
    final shipmentId = int.tryParse(data['shipment_id']?.toString() ?? '');

    if (app == 'client' && shipmentId != null) {
      AppRouter.router.go('/history/detail', extra: shipmentId);
      return;
    }
    if (app == 'carrier') {
      AppRouter.router.go('/home-carrier');
      return;
    }

    final route = _extractRoute(data);
    if (route != null && route.startsWith('/')) {
      AppRouter.router.go(route);
    }
  }

  String? _extractRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;
    final deepLink = data['deep_link']?.toString();
    if (deepLink != null && deepLink.startsWith('/')) return deepLink;
    return null;
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);

  Future<void> unsubscribeFrom(String topic) => _fm.unsubscribeFromTopic(topic);

  Future<void> registerOnServerOnce({required String kind}) async {
    final token = _lastToken ?? await _fm.getToken();
    if (token == null || token.isEmpty) return;

    final api = ApiService();
    final bearer = api.currentAccessToken;
    if (bearer == null || bearer.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'fcm_registered_token_$kind';
    if (prefs.getString(key) == token) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    try {
      await api.postFcmRegister(token: token, platform: platform);
      await prefs.setString(key, token);
    } catch (_) {
      // Следующий вход на домашний экран повторит регистрацию.
    }
  }
}
''',
    encoding="utf-8",
)

# Carrier screen: restore accepted work, retain persisted progress, and remove placeholder copy.
replace_once(
    "lib/features/carrier_module/home/carrier_home_screen.dart",
    '''    _initLocation();
  }
''',
    '''    Future.microtask(_bootstrapCarrier);
  }

  Future<void> _bootstrapCarrier() async {
    await _restoreActiveShipment();
    await _initLocation();
  }

  Future<void> _restoreActiveShipment() async {
    try {
      final page = await ApiService.instance.getShipments(page: 1, pageSize: 100);
      final rawResults = page['results'];
      if (rawResults is! List) return;

      for (final raw in rawResults) {
        if (raw is! Map) continue;
        final json = Map<String, dynamic>.from(raw);
        final status = parseShipmentStatus((json['status'] ?? '').toString());
        if (status != ShipmentStatus.assigned &&
            status != ShipmentStatus.inTransit) {
          continue;
        }

        final parsed = _parseActive(json);
        if (!mounted || parsed.id <= 0) return;
        setState(() {
          _activeId = parsed.id;
          _activePublicCode = parsed.publicCode;
          _activeStatus = parsed.status;
          _activeCurrentStopIndex = parsed.currentStopIndex;
          _activeStops = parsed.stops;
          _activeFare = parsed.fare;
          _showWelcome = false;
          _showEmptyOrders = false;
          _nearby = const [];
          _nearbyIndex = 0;
        });
        _startPolling(parsed.id);
        await _syncRouteAndCameraForActive();
        return;
      }
    } catch (_) {
      // Нет активного заказа или сеть временно недоступна — остаёмся на welcome.
    }
  }
''',
)
replace_once(
    "lib/features/carrier_module/home/carrier_home_screen.dart",
    '''    } catch (e) {
      if (!mounted) return;
    }
  }

  void _startPolling(int id) {
''',
    '''    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, error: e);
    }
  }

  void _startPolling(int id) {
''',
)
replace_once(
    "lib/features/carrier_module/home/carrier_home_screen.dart",
    '''    return list.map((e) => int.parse(e)).toSet();
''',
    '''    return list.map(int.tryParse).whereType<int>().toSet();
''',
)
replace_once(
    "lib/features/carrier_module/home/carrier_home_screen.dart",
    '''                'Сатурн — шестая планета по удалённости от Солнца и вторая по размерам планета',
''',
    '''                'Направляйтесь к первой точке и нажмите «Начать» после получения груза.',
''',
)

# Finik polling cannot overlap; technical exception strings are not user-facing.
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    "import 'package:flutter/foundation.dart';\n",
    "import 'package:flutter/foundation.dart';\nimport '../../../../core/utils/friendly_error.dart';\n",
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    "  int _pollTicks = 0;\n",
    "  int _pollTicks = 0;\n  bool _pollInFlight = false;\n",
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    "    _pollTicks = 0;\n    status = FinikFlowStatus.initial;\n",
    "    _pollTicks = 0;\n    _pollInFlight = false;\n    status = FinikFlowStatus.initial;\n",
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    "      errorText = e.toString();\n      notifyListeners();\n      rethrow;\n",
    "      errorText = friendlyErrorMessage(e, fallback: 'Не удалось начать оплату');\n      notifyListeners();\n      rethrow;\n",
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    "      errorText = e.toString();\n      notifyListeners();\n    }\n  }\n\n  void startPollingPaid",
    "      errorText = friendlyErrorMessage(e, fallback: 'Не удалось начать оплату');\n      notifyListeners();\n    }\n  }\n\n  void startPollingPaid",
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    '''    _pollTimer = Timer.periodic(interval, (t) async {
      _pollTicks++;

      try {
''',
    '''    _pollTimer = Timer.periodic(interval, (t) async {
      if (_pollInFlight) return;
      _pollInFlight = true;
      _pollTicks++;

      try {
''',
)
replace_once(
    "lib/features/main_module/payments/provider/finik_payment_flow_provider.dart",
    '''      } catch (e) {
        if (_pollTicks >= maxTicks) {
          t.cancel();
          status = FinikFlowStatus.failed;
          errorText = e.toString();
          notifyListeners();
        }
      }
    });
''',
    '''      } catch (e) {
        if (_pollTicks >= maxTicks) {
          t.cancel();
          status = FinikFlowStatus.failed;
          errorText = friendlyErrorMessage(
            e,
            fallback: 'Не удалось проверить статус оплаты',
          );
          notifyListeners();
        }
      } finally {
        _pollInFlight = false;
      }
    });
''',
)

# A build-triggered delayed pop could be scheduled repeatedly. Keep success explicit.
replace_once(
    "lib/features/main_module/payments/view/finik_payment_screen.dart",
    '''  Widget _buildSuccessCard(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      });
    });

    return Container(
''',
    '''  Widget _buildSuccessCard(BuildContext context) {
    return Container(
''',
)
replace_once(
    "lib/features/main_module/payments/view/finik_payment_screen.dart",
    '''          const Text(
            'Заказ успешно оплачен',
            style: TextStyle(fontSize: 16, color: AppColors.grey2),
          ),
        ],
''',
    '''          const Text(
            'Заказ успешно оплачен',
            style: TextStyle(fontSize: 16, color: AppColors.grey2),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Готово'),
            ),
          ),
        ],
''',
)

# Regression model coverage for all history status buckets.
Path("test/full_system_contract_test.dart").write_text(
    '''import 'package:dogo/features/main_module/history/data/model/shipment_history_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history page keeps active, completed and canceled statuses', () {
    final page = ShipmentHistoryPage.fromJson({
      'count': 3,
      'results': [
        {'id': 1, 'status': 'pending', 'created_at': '2026-01-01T00:00:00Z'},
        {'id': 2, 'status': 'completed', 'created_at': '2026-01-02T00:00:00Z'},
        {'id': 3, 'status': 'canceled', 'created_at': '2026-01-03T00:00:00Z'},
      ],
    });

    expect(page.count, 3);
    expect(page.results.map((item) => item.status), [
      'pending',
      'completed',
      'canceled',
    ]);
  });
}
''',
    encoding="utf-8",
)

print("Flutter hardening patch applied")
