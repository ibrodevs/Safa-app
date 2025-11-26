import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/model/delivery_autocomplete_result.dart';
import '../data/repo/delivery_geo_repository.dart';

class DeliveryAutocompleteProvider extends ChangeNotifier {
  final DeliveryGeoRepository _repo;

  DeliveryAutocompleteProvider(this._repo);

  final List<DeliveryAutocompleteResult> _items = [];
  List<DeliveryAutocompleteResult> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Timer? _debounce;
  String _lastQuery = '';

  void onQueryChanged(String raw) {
    final q = raw.trim();
    _lastQuery = q;

    _debounce?.cancel();

    if (q.isEmpty) {
      _items.clear();
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(q);
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _repo.autocomplete(q);

      if (q != _lastQuery) return;

      _items
        ..clear()
        ..addAll(res);
    } catch (e, st) {
      if (kDebugMode) {
        print('DeliveryAutocompleteProvider error: $e\n$st');
      }
      _error = e.toString();
      _items.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _debounce?.cancel();
    _items.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
