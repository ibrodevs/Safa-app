import 'package:flutter/foundation.dart';

import '../data/model/shipment_detail_model.dart';
import '../data/repo/shipment_detail_repo.dart';

class ShipmentDetailProvider extends ChangeNotifier {
  final ShipmentDetailRepository _repo;

  ShipmentDetailProvider(this._repo);

  ShipmentDetail? _detail;
  ShipmentDetail? get detail => _detail;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _detail = await _repo.fetchDetail(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
