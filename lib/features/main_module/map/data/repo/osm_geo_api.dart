import 'dart:convert';
import 'package:dio/dio.dart';

class OsmGeoApi {
  OsmGeoApi(this._dio);

  final Dio _dio;

  static const _ua = 'dogo-app/1.0 (contact: your-email@example.com)';

  Future<List<Map<String, dynamic>>> autocompleteRaw(String query) async {
    final r = await _dio.get(
      'https://photon.komoot.io/api/',
      queryParameters: {
        'q': query,
        'limit': 8,
        'lang': 'ru',
      },
      options: Options(
        headers: {'User-Agent': _ua},
        sendTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        validateStatus: (_) => true,
      ),
    );

    final sc = r.statusCode ?? -1;
    final t = r.data.runtimeType.toString();
    final preview = _preview(r.data);
    print('PHOTON_AUTOCOMPLETE sc=$sc type=$t body=$preview');

    if (sc != 200) return const [];

    final data = r.data;
    if (data is! Map<String, dynamic>) return const [];

    final features = (data['features'] as List?) ?? const [];

    return features.map<Map<String, dynamic>>((f) {
      final props = (f is Map ? f['properties'] : null);
      final geometry = (f is Map ? f['geometry'] : null);

      final propsMap = (props is Map) ? props.cast<String, dynamic>() : <String, dynamic>{};
      final coords = ((geometry is Map ? geometry['coordinates'] : null) as List?) ?? const [0, 0];

      final lon = (coords.isNotEmpty && coords[0] is num) ? (coords[0] as num).toDouble() : 0.0;
      final lat = (coords.length > 1 && coords[1] is num) ? (coords[1] as num).toDouble() : 0.0;

      final name = (propsMap['name'] ?? '').toString();
      final city = (propsMap['city'] ?? propsMap['state'] ?? '').toString();
      final street = (propsMap['street'] ?? '').toString();
      final housenumber = (propsMap['housenumber'] ?? '').toString();

      final address = [
        if (city.isNotEmpty) city,
        if (street.isNotEmpty) street,
        if (housenumber.isNotEmpty) housenumber,
      ].join(', ');

      return {
        'title': name.isNotEmpty ? name : address,
        'address': address.isNotEmpty ? address : name,
        'lat': lat,
        'lon': lon,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> reverseRaw({
    required double lat,
    required double lon,
  }) async {
    final nom = await _reverseNominatimDebug(lat: lat, lon: lon);
    if (nom.trim().isNotEmpty) return {'address': nom};

    final ph = await _reversePhotonDebug(lat: lat, lon: lon);
    return {'address': ph};
  }

  Future<String> _reverseNominatimDebug({
    required double lat,
    required double lon,
  }) async {
    try {
      final r = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'jsonv2',
          'accept-language': 'ru',
          'zoom': 18,
          'email': 'senya.kalchoroev@gmail.com',
        },
        options: Options(
          headers: {'User-Agent': _ua},
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (_) => true,
        ),
      );

      final sc = r.statusCode ?? -1;
      final t = r.data.runtimeType.toString();
      final preview = _preview(r.data);

      print('NOMINATIM sc=$sc type=$t body=$preview');

      if (sc != 200) return '';

      if (r.data is Map<String, dynamic>) {
        final data = r.data as Map<String, dynamic>;
        return (data['display_name'] ?? '').toString().trim();
      }

      return '';
    } catch (e, st) {
      print('NOMINATIM EX: $e\n$st');
      return '';
    }
  }

  Future<String> _reversePhotonDebug({
    required double lat,
    required double lon,
  }) async {
    try {
      final r = await _dio.get(
        'https://photon.komoot.io/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': 5.0,
          'lang': 'default',
        },
        options: Options(
          headers: {'User-Agent': _ua},
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (_) => true,
        ),
      );

      final sc = r.statusCode ?? -1;
      final t = r.data.runtimeType.toString();
      final preview = _preview(r.data);

      print('PHOTON sc=$sc type=$t body=$preview');

      if (sc != 200) return '';
      if (r.data is! Map<String, dynamic>) return '';

      final data = r.data as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? const [];
      if (features.isEmpty) return '';

      final f = features.first;
      if (f is! Map) return '';

      final props = f['properties'];
      final propsMap = (props is Map) ? props.cast<String, dynamic>() : <String, dynamic>{};

      final name = (propsMap['name'] ?? '').toString();
      final city = (propsMap['city'] ?? propsMap['state'] ?? '').toString();
      final street = (propsMap['street'] ?? '').toString();
      final housenumber = (propsMap['housenumber'] ?? '').toString();

      final address = [
        if (city.isNotEmpty) city,
        if (street.isNotEmpty) street,
        if (housenumber.isNotEmpty) housenumber,
        if (name.isNotEmpty && name != street) name,
      ].where((e) => e.trim().isNotEmpty).join(', ');

      return address.trim();
    } catch (e, st) {
      print('PHOTON EX: $e\n$st');
      return '';
    }
  }

  String _preview(dynamic data) {
    try {
      final s = data is String ? data : jsonEncode(data);
      if (s.length <= 220) return s;
      return s.substring(0, 220);
    } catch (_) {
      return data.toString();
    }
  }
}
