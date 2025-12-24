import 'package:flutter/foundation.dart';

import '../data/model/delivery_reverse_geo.dart';
import '../data/repo/delivery_geo_repository.dart';

class DeliveryAddressProvider extends ChangeNotifier {
  final DeliveryGeoRepository _repo;

  DeliveryAddressProvider(this._repo);

  DeliveryReverseGeo? _here;
  bool _loading = false;
  String? _error;

  DeliveryReverseGeo? get here => _here;
  String? get hereAddress => _here?.address;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchHereAddress({required double lat, required double lon}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('reverse request: lat=$lat lon=$lon');
      final result = await _repo.getAddress(lat: lat, lon: lon);
      debugPrint('reverse response: ${result.address}');
      _here = result;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('fetchHereAddress error: $e\n$st');
      _here = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

}
