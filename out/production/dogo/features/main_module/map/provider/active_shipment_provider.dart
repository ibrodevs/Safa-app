import 'package:flutter/foundation.dart';

import '../../payments/data/repo/shipments_repository.dart';

enum ActiveShipmentLoadState { idle, loading, ready, error }

final class ActiveShipmentProvider extends ChangeNotifier {
  ActiveShipmentProvider({required ShipmentsRepository repo}) : _repo = repo;

  final ShipmentsRepository _repo;

  ActiveShipmentLoadState state = ActiveShipmentLoadState.idle;
  String? errorText;

  ShipmentsListItemDto? active;

  Future<void> load() async {
    state = ActiveShipmentLoadState.loading;
    errorText = null;
    notifyListeners();

    try {
      active = await _repo.getActiveShipment();
      state = ActiveShipmentLoadState.ready;
      notifyListeners();
    } catch (e) {
      state = ActiveShipmentLoadState.error;
      errorText = e.toString();
      notifyListeners();
    }
  }

  Future<ShipmentsListItemDto> getById(int id) {
    return _repo.getShipmentById(id);
  }

  void clear() {
    active = null;
    errorText = null;
    state = ActiveShipmentLoadState.ready;
    notifyListeners();
  }
}

