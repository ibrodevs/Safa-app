import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/init.dart' as yandex_init;
import 'package:yandex_maps_mapkit/mapkit_factory.dart';

abstract final class SafaMapKitConfig {
  static const apiKey = String.fromEnvironment(
    'MAPKIT_API_KEY',
    defaultValue: '49a7f194-1555-4fb0-b929-8db57956ba1d',
  );
  static bool get isConfigured => apiKey.trim().isNotEmpty;
}

final safaMapKitRuntime = SafaMapKitRuntime(
  initialize: () =>
      yandex_init.initMapkit(apiKey: SafaMapKitConfig.apiKey, locale: 'ru_RU'),
  onReady: () {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      mapkit.onStart();
    }
  },
);

/// Shares one initialization across startup and every map screen. Creating an
/// iOS platform view before initMapkit completes can abort the native process;
/// catching Dart errors around initialization alone cannot protect that view.
class SafaMapKitRuntime {
  SafaMapKitRuntime({
    required Future<void> Function() initialize,
    required VoidCallback onReady,
    this.timeout = const Duration(seconds: 10),
  }) : _initialize = initialize,
       _onReady = onReady;

  final Future<void> Function() _initialize;
  final VoidCallback _onReady;
  final Duration timeout;
  Future<bool>? _initialization;
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<bool> ensureInitialized() => _initialization ??= _initializeOnce();

  Future<bool> _initializeOnce() async {
    if (!SafaMapKitConfig.isConfigured) return false;
    try {
      await _initialize().timeout(timeout);
      _onReady();
      _isReady = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint('MapKit initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}

/// The builder must create the native view only after initialization succeeds.
class SafaMapKitGate extends StatelessWidget {
  const SafaMapKitGate({super.key, required this.builder, this.runtime});

  final WidgetBuilder builder;
  final SafaMapKitRuntime? runtime;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: (runtime ?? safaMapKitRuntime).ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data != true) {
          return const ColoredBox(
            color: Color(0xFFF2F4F7),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Не удалось загрузить карту. Перезапустите приложение.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return builder(context);
      },
    );
  }
}
