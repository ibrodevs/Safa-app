import 'package:flutter/foundation.dart';
import 'package:dogo/data/network/model/api_exeptions_model.dart';

import '../data/model/app_notification_model.dart';
import '../data/repo/notifications_repo.dart';

enum NotificationsReadFilter { all, unread, read }

extension NotificationsReadFilterX on NotificationsReadFilter {
  String? toQueryValue() {
    switch (this) {
      case NotificationsReadFilter.all:
        return null;
      case NotificationsReadFilter.unread:
        return '0';
      case NotificationsReadFilter.read:
        return '1';
    }
  }

  String label() {
    switch (this) {
      case NotificationsReadFilter.all:
        return 'Все';
      case NotificationsReadFilter.unread:
        return 'Непрочит.';
      case NotificationsReadFilter.read:
        return 'Прочит.';
    }
  }
}

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this.repo);

  final NotificationsRepository repo;

  final List<AppNotificationModel> _items = [];
  List<AppNotificationModel> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  int _page = 1;
  final int _pageSize = 20;

  NotificationsReadFilter _filter = NotificationsReadFilter.all;

  final Set<int> _marking = <int>{};

  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  NotificationsReadFilter get filter => _filter;

  int get unreadCount => _items.where((e) => !e.isRead).length;

  void setFilter(NotificationsReadFilter v) {
    if (_filter == v) return;
    _filter = v;
    notifyListeners();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    _hasMore = true;
    _page = 1;
    _items.clear();
    notifyListeners();

    try {
      final list = await repo.getNotifications(
        page: 1,
        pageSize: _pageSize,
        isRead: _filter.toQueryValue(),
      );

      _items.addAll(list);
      _hasMore = list.length >= _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Не удалось загрузить уведомления';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;
    notifyListeners();

    try {
      final list = await repo.getNotifications(
        page: 1,
        pageSize: _pageSize,
        isRead: _filter.toQueryValue(),
      );

      _items
        ..clear()
        ..addAll(list);

      _page = 1;
      _hasMore = list.length >= _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Не удалось обновить';
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;

    _loadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _page + 1;

      final list = await repo.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
        isRead: _filter.toQueryValue(),
      );

      _items.addAll(list);
      _page = nextPage;
      _hasMore = list.length >= _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Не удалось догрузить';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    if (_marking.contains(id)) return;

    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final old = _items[idx];
    if (old.isRead) return;

    _marking.add(id);

    final updated = old.copyWith(isRead: true, readAt: DateTime.now());
    if (_filter == NotificationsReadFilter.unread) {
      _items.removeAt(idx);
    } else {
      _items[idx] = updated;
    }
    notifyListeners();

    try {
      await repo.markRead(id);
    } on ApiException catch (e) {
      _rollbackMarkRead(idx, old);
      _error = e.message;
      notifyListeners();
    } catch (_) {
      _rollbackMarkRead(idx, old);
      _error = 'Не удалось отметить как прочитанное';
      notifyListeners();
    } finally {
      _marking.remove(id);
    }
  }

  void _rollbackMarkRead(int idx, AppNotificationModel old) {
    if (_filter == NotificationsReadFilter.unread) {
      final insertAt = idx <= _items.length ? idx : _items.length;
      _items.insert(insertAt, old);
    } else {
      if (idx < _items.length) {
        _items[idx] = old;
      } else {
        _items.add(old);
      }
    }
  }
}
