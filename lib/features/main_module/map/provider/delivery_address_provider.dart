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
  int _gpsRequestSerial = 0;
  int _pickerRequestSerial = 0;

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
    bool preferPublicAddress = false,
  }) async {
    final serial = ++_gpsRequestSerial;
    _gpsLoading = true;
    _gpsError = null;
    _gpsHere = null;
    notifyListeners();
    try {
      debugPrint('reverse GPS: lat=$lat lon=$lon');
      final result = await _repo.getAddress(
        lat: lat,
        lon: lon,
        preferPublicAddress: preferPublicAddress,
      );
      if (serial != _gpsRequestSerial) return;
      debugPrint('reverse GPS ok: ${result.address}');
      _gpsHere = result;
    } catch (e, st) {
      if (serial != _gpsRequestSerial) return;
      _gpsError = e.toString();
      debugPrint('fetchGpsHereAddress error: $e\n$st');
      _gpsHere = null;
    } finally {
      if (serial == _gpsRequestSerial) {
        _gpsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchPickerHereAddress({
    required double lat,
    required double lon,
    bool preferPublicAddress = false,
  }) async {
    final serial = ++_pickerRequestSerial;
    _pickerLoading = true;
    _pickerError = null;
    _pickerHere = null;
    notifyListeners();
    try {
      debugPrint('reverse PICKER: lat=$lat lon=$lon');
      final result = await _repo.getAddress(
        lat: lat,
        lon: lon,
        preferPublicAddress: preferPublicAddress,
      );
      if (serial != _pickerRequestSerial) return;
      debugPrint('reverse PICKER ok: ${result.address}');
      _pickerHere = result;
    } catch (e, st) {
      if (serial != _pickerRequestSerial) return;
      _pickerError = e.toString();
      debugPrint('fetchPickerHereAddress error: $e\n$st');
      _pickerHere = null;
    } finally {
      if (serial == _pickerRequestSerial) {
        _pickerLoading = false;
        notifyListeners();
      }
    }
  }

  void clearPickerHere() {
    _pickerRequestSerial += 1;
    _pickerHere = null;
    _pickerError = null;
    _pickerLoading = false;
    notifyListeners();
  }
}
