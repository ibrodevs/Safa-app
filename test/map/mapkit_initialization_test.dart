import 'dart:async';

import 'package:dogo/core/map/safa_mapkit_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'early navigation waits for SDK and shares startup initialization',
    (tester) async {
      final initialized = Completer<void>();
      var initCalls = 0;
      var starts = 0;
      var viewsCreated = 0;
      final runtime = SafaMapKitRuntime(
        initialize: () {
          initCalls++;
          return initialized.future;
        },
        onReady: () => starts++,
      );
      final startup = runtime.ensureInitialized();
      Widget screen() => MaterialApp(
        home: SafaMapKitGate(
          runtime: runtime,
          builder: (_) {
            expect(runtime.isReady, isTrue);
            viewsCreated++;
            return const Text('Map');
          },
        ),
      );

      await tester.pumpWidget(screen());
      await tester.pumpWidget(screen());
      expect(viewsCreated, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(initCalls, 1);
      expect(starts, 0);

      initialized.complete();
      await tester.pumpAndSettle();
      expect(await startup, isTrue);
      expect(find.text('Map'), findsOneWidget);
      expect(starts, 1);
      expect(initCalls, 1);
    },
  );

  testWidgets('SDK error displays fallback without creating a native view', (
    tester,
  ) async {
    var viewsCreated = 0;
    final runtime = SafaMapKitRuntime(
      initialize: () async => throw StateError('SDK unavailable'),
      onReady: () => fail('Failed SDK must not start'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SafaMapKitGate(
          runtime: runtime,
          builder: (_) {
            viewsCreated++;
            return const Text('Map');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(viewsCreated, 0);
    expect(runtime.isReady, isFalse);
    expect(find.textContaining('Не удалось загрузить карту'), findsOneWidget);
  });

  testWidgets('late SDK completion after timeout cannot create a map', (
    tester,
  ) async {
    final initialized = Completer<void>();
    var viewsCreated = 0;
    final runtime = SafaMapKitRuntime(
      initialize: () => initialized.future,
      onReady: () => fail('Timed out SDK must not start'),
      timeout: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SafaMapKitGate(
          runtime: runtime,
          builder: (_) {
            viewsCreated++;
            return const Text('Map');
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.textContaining('Не удалось загрузить карту'), findsOneWidget);
    initialized.complete();
    await tester.pumpAndSettle();
    expect(runtime.isReady, isFalse);
    expect(viewsCreated, 0);
    expect(await runtime.ensureInitialized(), isFalse);
  });
}
