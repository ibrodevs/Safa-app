import 'package:dogo/core/map/safa_yandex_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit/yandex_map.dart';

void main() {
  tearDown(() {
    SafaMapKitRuntime.status.value = SafaMapKitStatus.initializing;
  });

  testWidgets('does not mount native YandexMap before MapKit is ready', (
    tester,
  ) async {
    SafaMapKitRuntime.status.value = SafaMapKitStatus.initializing;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafaYandexMap(
            controller: SafaMapController(),
            initialCenter: const LatLng(42.8746, 74.5698),
          ),
        ),
      ),
    );

    expect(find.byType(YandexMap), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a recoverable message instead of a native view on error', (
    tester,
  ) async {
    SafaMapKitRuntime.status.value = SafaMapKitStatus.initializing;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafaYandexMap(
            controller: SafaMapController(),
            initialCenter: const LatLng(42.8746, 74.5698),
          ),
        ),
      ),
    );

    SafaMapKitRuntime.status.value = SafaMapKitStatus.failed;
    await tester.pump();

    expect(find.byType(YandexMap), findsNothing);
    expect(find.textContaining('Не удалось запустить карту'), findsOneWidget);
  });
}
