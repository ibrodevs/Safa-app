import 'package:dogo/features/main_module/history/data/model/shipment_history_models.dart';
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
