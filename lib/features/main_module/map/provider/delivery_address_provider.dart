import 'package:flutter/foundation.dart';
import '../data/model/delivery_reverse_geo.dart';
import '../data/repo/delivery_geo_repository.dart';

class DeliveryAddressProvider extends ChangeNotifier {
  final DeliveryGeoRepository _repo;

  DeliveryAddressProvider(this._repo);

  DeliveryReverseGeo? _gpsHere;
  bool _gpsLoading = false;
  String? _gpsError;

  DeliveryReverseGeo? _pickerHere;
  bool _pickerLoading = false;
  String? _pickerError;

  String? _fromAddress;
  double? _fromLat;
  double? _fromLon;

  DeliveryReverseGeo? get gpsHere => _gpsHere;
  String? get gpsHereAddress => _gpsHere?.address;
  bool get gpsLoading => _gpsLoading;
  String? get gpsError => _gpsError;

  DeliveryReverseGeo? get pickerHere => _pickerHere;
  String? get pickerHereAddress => _pickerHere?.address;
  bool get pickerLoading => _pickerLoading;
  String? get pickerError => _pickerError;

  String? get fromAddress => _fromAddress;
  double? get fromLat => _fromLat;
  double? get fromLon => _fromLon;

  void setFromAddress({required String address, double? lat, double? lon}) {
    final a = address.trim();
    if (a.isEmpty) {
      clearFromAddress();
      return;
    }
    _fromAddress = a;
    _fromLat = lat;
    _fromLon = lon;
    notifyListeners();
  }

  void clearFromAddress() {
    _fromAddress = null;
    _fromLat = null;
    _fromLon = null;
    notifyListeners();
  }

  Future<void> fetchGpsHereAddress({
    required double lat,
    required double lon,
  }) async {
    _gpsLoading = true;
    _gpsError = null;
    notifyListeners();
    try {
      debugPrint('reverse GPS: lat=$lat lon=$lon');
      final result = await _repo.getAddress(lat: lat, lon: lon);
      debugPrint('reverse GPS ok: ${result.address}');
      _gpsHere = result;
    } catch (e, st) {
      _gpsError = e.toString();
      debugPrint('fetchGpsHereAddress error: $e\n$st');
      _gpsHere = null;
    } finally {
      _gpsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPickerHereAddress({
    required double lat,
    required double lon,
  }) async {
    _pickerLoading = true;
    _pickerError = null;
    notifyListeners();
    try {
      debugPrint('reverse PICKER: lat=$lat lon=$lon');
      final result = await _repo.getAddress(lat: lat, lon: lon);
      debugPrint('reverse PICKER ok: ${result.address}');
      _pickerHere = result;
    } catch (e, st) {
      _pickerError = e.toString();
      debugPrint('fetchPickerHereAddress error: $e\n$st');
      _pickerHere = null;
    } finally {
      _pickerLoading = false;
      notifyListeners();
    }
  }

  void clearPickerHere() {
    _pickerHere = null;
    _pickerError = null;
    _pickerLoading = false;
    notifyListeners();
  }
}
