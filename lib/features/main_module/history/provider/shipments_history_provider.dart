import 'package:flutter/foundation.dart';

import '../../../../core/utils/friendly_error.dart';
import '../data/model/shipment_history_models.dart';
import '../data/repo/shipments_history_repo.dart';

class ShipmentsHistoryProvider extends ChangeNotifier {
  final ShipmentsHistoryRepository _repo;

  ShipmentsHistoryProvider(this._repo);

  static const int _pageSize = 10;

  final List<ShipmentHistoryItem> _items = [];
  List<ShipmentHistoryItem> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  int _page = 1;
  int _totalCount = 0;

  bool get canLoadMore => _items.length < _totalCount;

  Future<void> refresh() async {
    _loading = true;
    _loadingMore = false;
    _error = null;
    _page = 1;
    notifyListeners();

    try {
      final page = await _repo.fetchPage(page: _page, pageSize: _pageSize);
      _totalCount = page.count;
      _items
        ..clear()
        ..addAll(page.results);
    } catch (e) {
      // Пользователю показывается человекочитаемый текст, а не `e.toString()`
      // с HTML-ответом сервера или `DioException [...]`.
      _error = friendlyErrorMessage(e, fallback: 'Не удалось загрузить заказы');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !canLoadMore) return;

    _loadingMore = true;
    _error = null;
    _page += 1;
    notifyListeners();

    try {
      final page = await _repo.fetchPage(page: _page, pageSize: _pageSize);
      _totalCount = page.count;
      _items.addAll(page.results);
    } catch (e) {
      _page -= 1;
      _error = friendlyErrorMessage(e, fallback: 'Не удалось загрузить заказы');
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}
