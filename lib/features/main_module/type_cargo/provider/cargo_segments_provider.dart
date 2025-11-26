import 'package:flutter/foundation.dart';

import '../data/model/cargo_segment_model.dart';
import '../data/repo/cargo_segments_repo.dart';

class CargoSegmentsProvider extends ChangeNotifier {
  CargoSegmentsProvider(this._repo);

  final CargoSegmentsRepository _repo;

  List<CargoSegment> _items = [];
  List<CargoSegment> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _repo.getSegments();
      _items = res;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
