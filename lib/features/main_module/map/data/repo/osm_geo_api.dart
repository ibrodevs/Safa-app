import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../../../core/utils/address_format.dart';
import '../../../../../core/utils/app_logger.dart';

class OsmGeoApi {
  OsmGeoApi(this._dio);

  final Dio _dio;

  static const _ua = 'dogo-app/1.0 (contact: your-email@example.com)';

  Future<List<Map<String, dynamic>>> autocompleteRaw(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    final dordoiKeywords = [
      'проход',
      'ряд',
      'контейнер',
      'дордой',
      'мурас',
      'алкан',
      'европа',
      'оберон',
      'джунхай',
      'кербен',
      'ак-суу',
      'север',
      'восток',
      'центральный',
      'кишка',
    ];
    final isDordoiQuery =
        dordoiKeywords.any((kw) => cleanQuery.toLowerCase().contains(kw)) ||
        RegExp(r'\b\d+\s*[-/]?\s*(?:проход|ряд)\b|\b(?:проход|ряд)\s*\d+\b', caseSensitive: false).hasMatch(cleanQuery) ||
        RegExp(r'^\d+\s*[,/ -]\s*\d+(?:[/ -]\d+)?$').hasMatch(cleanQuery);

    final results = <Map<String, dynamic>>[];

    if (isDordoiQuery) {
      final yandexMatches = await _searchYandexWeb(cleanQuery);
      if (yandexMatches.isNotEmpty) {
        results.addAll(yandexMatches);
      } else {
        String passage = '';
        String container = '';
        String sector = '';

      for (final s in [
        'мурас-спорт',
        'мурас спорт',
        'китай',
        'алкан',
        'алканов',
        'европа',
        'оберон',
        'джунхай',
        'кербен',
        'ак-суу',
        'восток',
        'север',
        'автозапчасти',
      ]) {
        if (cleanQuery.toLowerCase().contains(s)) {
          final String sTitle;
          if (s.contains('мурас')) {
            sTitle = 'Мурас-Спорт';
          } else if (s.contains('алкан')) {
            sTitle = 'Алкан';
          } else if (s.contains('ак-суу')) {
            sTitle = 'Ак-Суу';
          } else {
            sTitle = s[0].toUpperCase() + s.substring(1);
          }
          sector = 'рынок $sTitle';
          break;
        }
      }

      final mPass = RegExp(
        r'(\d+)(?:[-–—]?(?:й|ой|ий|ый))?\s*проход|проход\s*(?:№\s*)?([0-9a-zA-Zа-яА-Я]+)',
        caseSensitive: false,
      ).firstMatch(cleanQuery);
      if (mPass != null) {
        final pNum = mPass.group(1) ?? mPass.group(2) ?? '';
        passage = int.tryParse(pNum) != null ? '$pNum-й проход' : 'проход $pNum';
      } else if (cleanQuery.toLowerCase().contains('центральный')) {
        passage = 'проход Центральный';
      }

      var rem = cleanQuery;
      if (passage.isNotEmpty) {
        rem = rem.replaceAll(
          RegExp(r'(?:\d+[-–—]?(?:й|ой|ий|ый)?\s*проход|проход\s*[0-9a-zA-Zа-яА-Я]+|проход|центральный)', caseSensitive: false),
          '',
        );
      }
      if (sector.isNotEmpty) {
        rem = rem.replaceAll(
          RegExp(r'мурас[- ]?спорт|алкан(?:ов)?|европа|оберон|джунхай|кербен|ак-суу|восток|север|автозапчасти', caseSensitive: false),
          '',
        );
      }
      rem = rem.replaceAll(RegExp(r'контейнер|дордой|рынок', caseSensitive: false), '').replaceAll(RegExp(r'^[ ,.-/]+|[ ,.-/]+$'), '').trim();
      if (rem.isNotEmpty) {
        container = rem;
      }

      if (passage.isEmpty && container.isEmpty) {
        final m = RegExp(r'^(\d+)\s*[,/ -]\s*(\d+)(?:[/ -](\d+))?$').firstMatch(cleanQuery);
        if (m != null) {
          container = m.group(1) ?? '';
          passage = '${m.group(2)}-й проход';
          if (m.group(3) != null) {
            container = '$container/${m.group(3)}';
          }
        }
      }

      final parts = <String>[];
      if (passage.isNotEmpty) parts.add(passage);
      if (container.isNotEmpty) parts.add(container);
      if (sector.isNotEmpty) parts.add(sector);
      parts.add('рынок Дордой');
      parts.add('Бишкек');

      final titleParts = [passage, container, sector].where((p) => p.isNotEmpty).toList();
      final title = titleParts.isNotEmpty ? titleParts.join(', ') : 'рынок Дордой';
      final fullAddress = parts.join(', ');

      results.add({
        'title': title,
        'address': fullAddress,
        'lat': 42.9367,
        'lon': 74.6217,
      });
    }
  }

    final searchQ = cleanQuery.toLowerCase().contains('бишкек')
        ? cleanQuery
        : 'Бишкек $cleanQuery';

    try {
      final r = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': searchQ,
          'format': 'jsonv2',
          'accept-language': 'ru',
          'addressdetails': 1,
          'countrycodes': 'kg',
          'viewbox': '74.45,42.99,74.75,42.75',
          'limit': 10,
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
      if (sc == 200 && r.data is List) {
        final list = (r.data as List).whereType<Map>().toList();
        final seen = results.map((e) => e['address'].toString()).toSet();
        for (final item in list) {
          final m = Map<String, dynamic>.from(item);
          final addr = (m['address'] is Map)
              ? Map<String, dynamic>.from(m['address'] as Map)
              : <String, dynamic>{};

          final road = (addr['road'] ?? addr['pedestrian'] ?? '').toString().trim();
          final house = (addr['house_number'] ?? '').toString().trim();
          final city = (addr['city'] ?? addr['town'] ?? 'Бишкек').toString().trim();
          final name = (m['name'] ?? road).toString().trim();
          final place = (addr['shop'] ?? addr['amenity'] ?? addr['marketplace'] ?? addr['suburb'] ?? '').toString().trim();

          final parts = [road.isNotEmpty ? road : place, house, city.isNotEmpty ? city : 'Бишкек'].where((p) => p.isNotEmpty).toList();
          final title = (road.isNotEmpty && house.isNotEmpty)
              ? '$road, $house'
              : (road.isNotEmpty ? road : (name.isNotEmpty ? name : m['display_name'].toString()));
          final fullAddress = parts.isNotEmpty ? parts.join(', ') : m['display_name'].toString();

          final lat = double.tryParse(m['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(m['lon']?.toString() ?? '') ?? 0.0;

          if (!seen.contains(fullAddress)) {
            seen.add(fullAddress);
            results.add({
              'title': title,
              'address': fullAddress,
              'lat': lat,
              'lon': lon,
            });
          }
        }
      }
      return results;
    } catch (e) {
      AppLogger.d('OSM_AUTOCOMPLETE error=$e');
      return results;
    }
  }

  Future<Map<String, dynamic>> reverseRaw({
    required double lat,
    required double lon,
  }) async {
    final yandex = await _reverseYandexWeb(lat: lat, lon: lon);
    if (yandex.trim().isNotEmpty) return {'address': yandex};

    final nom = await _reverseNominatimDebug(lat: lat, lon: lon);
    if (nom.trim().isNotEmpty) return {'address': nom};

    final ph = await _reversePhotonDebug(lat: lat, lon: lon);
    return {'address': ph};
  }

  Future<String> _reverseYandexWeb({
    required double lat,
    required double lon,
  }) async {
    try {
      final r = await _dio.get(
        'https://yandex.ru/maps/',
        queryParameters: {
          'll': '$lon,$lat',
          'mode': 'search',
          'sll': '$lon,$lat',
          'text': '$lat,$lon',
          'z': 19,
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'ru-RU,ru;q=0.9',
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (_) => true,
        ),
      );
      if (r.statusCode == 200 && r.data is String) {
        final html = r.data as String;
        final m1 = RegExp(
          r'<meta\s+itemProp="description"\s+content="([^"]+)"',
        ).firstMatch(html);
        if (m1 != null) {
          final val = m1.group(1)?.trim() ?? '';
          if (val.isNotEmpty) return val;
        }
        final m2 = RegExp(
          r'class="toponym-card-title-view__description">([^<]+)</div>',
        ).firstMatch(html);
        if (m2 != null) {
          final val = m2.group(1)?.trim() ?? '';
          if (val.isNotEmpty) return val;
        }
      }
    } catch (e) {
      AppLogger.d('YANDEX_WEB EX: $e');
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> _searchYandexWeb(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    final searchTerms = <String>[];
    if (clean.toLowerCase().contains('ряд') && !clean.toLowerCase().contains('китай')) {
      searchTerms.add('Дордой Китай $clean');
      searchTerms.add('Дордой $clean');
    } else if (!clean.toLowerCase().contains('дордой')) {
      searchTerms.add('Дордой $clean');
    } else {
      searchTerms.add(clean);
    }

    final results = <Map<String, dynamic>>[];
    for (final term in searchTerms) {
      try {
        final r = await _dio.get(
          'https://yandex.ru/maps/',
          queryParameters: {'text': term, 'z': 19},
          options: Options(
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept-Language': 'ru-RU,ru;q=0.9',
            },
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
            validateStatus: (_) => true,
          ),
        );
        if (r.statusCode == 200 && r.data is String) {
          final html = r.data as String;
          final coordsMatch =
              RegExp(r'"coordinates":\[([0-9.]+),([0-9.]+)\]').firstMatch(html);
          final itemMatch =
              RegExp(r'"title":"([^"]+)","description":"([^"]+)"').firstMatch(html);
          if (coordsMatch != null && itemMatch != null) {
            final lon = double.tryParse(coordsMatch.group(1) ?? '') ?? 0.0;
            final lat = double.tryParse(coordsMatch.group(2) ?? '') ?? 0.0;
            final title = itemMatch.group(1) ?? '';
            final desc = itemMatch.group(2) ?? '';
            final full = '$title, $desc';
            if (lat != 0.0 && lon != 0.0) {
              results.add({
                'title': title,
                'address': full,
                'lat': lat,
                'lon': lon,
              });
              break;
            }
          }
        }
      } catch (e) {
        AppLogger.d('YANDEX_WEB_SEARCH EX: $e');
      }
    }
    return results;
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
          'addressdetails': 1,
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
      if (sc != 200) return '';

      if (r.data is Map<String, dynamic>) {
        return _composeNominatimAddress(r.data as Map<String, dynamic>, lat: lat, lon: lon);
      }

      return '';
    } catch (e, st) {
      AppLogger.d('NOMINATIM EX: $e\n$st');
      return '';
    }
  }

  String _composeNominatimAddress(
    Map<String, dynamic> data, {
    double lat = 0.0,
    double lon = 0.0,
  }) {
    final raw = data['address'];
    final address = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};

    String field(List<String> keys) {
      for (final key in keys) {
        final value = (address[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final city = field(['city', 'town', 'village', 'municipality']);
    final street = field(['road', 'pedestrian']);
    final house = field(['house_number']);
    final suburb = field(['suburb', 'neighbourhood', 'residential', 'quarter']);
    final place = field(['shop', 'amenity', 'marketplace', 'commercial']);

    final isDordoi =
        (lat >= 42.925 && lat <= 42.955 && lon >= 74.605 && lon <= 74.650) ||
        suburb.toLowerCase().contains('дордой') ||
        street.toLowerCase().contains('проход') ||
        place.toLowerCase().contains('дордой');

    if (isDordoi) {
      final parts = <String>[];
      if (street.isNotEmpty) {
        parts.add(street);
      } else if (place.isNotEmpty && !place.toLowerCase().contains('дордой')) {
        parts.add(place);
      } else if (suburb.isNotEmpty && !suburb.toLowerCase().contains('дордой')) {
        parts.add(suburb);
      }

      if (house.isNotEmpty) {
        parts.add(house);
      }

      String submarket = '';
      for (final cand in [place, suburb]) {
        final cLow = cand.toLowerCase();
        if (cand.isNotEmpty &&
            !cLow.contains('дордой') &&
            !cLow.contains('бишкек') &&
            cand != street) {
          submarket = cand;
          break;
        }
      }
      if (submarket.isNotEmpty) {
        final subClean = submarket.toLowerCase().startsWith('рынок')
            ? submarket
            : 'рынок $submarket';
        if (!parts.contains(subClean)) {
          parts.add(subClean);
        }
      }

      parts.add('рынок Дордой');
      parts.add('Бишкек');
      return parts.join(', ');
    }

    final streetPart = (street.isNotEmpty && house.isNotEmpty)
        ? '$street, $house'
        : (street.isNotEmpty ? street : place.isNotEmpty ? place : suburb);

    final composed = streetPart.isNotEmpty
        ? joinAddressParts([streetPart, city.isNotEmpty ? city : 'Бишкек'])
        : (city.isNotEmpty ? city : 'Бишкек');
    if (composed.isNotEmpty) return composed;

    return formatReadableAddress((data['display_name'] ?? '').toString());
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

      AppLogger.d('PHOTON sc=$sc type=$t body=$preview');

      if (sc != 200) return '';
      if (r.data is! Map<String, dynamic>) return '';

      final data = r.data as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? const [];
      if (features.isEmpty) return '';

      final f = features.first;
      if (f is! Map) return '';

      final props = f['properties'];
      final propsMap = (props is Map)
          ? props.cast<String, dynamic>()
          : <String, dynamic>{};

      final name = (propsMap['name'] ?? '').toString();
      final city = (propsMap['city'] ?? propsMap['state'] ?? '').toString();
      final street = (propsMap['street'] ?? '').toString();
      final housenumber = (propsMap['housenumber'] ?? '').toString();

      final address = joinAddressParts([
        city,
        street,
        housenumber,
        if (name != street) name,
      ]);

      return address.trim();
    } catch (e, st) {
      AppLogger.d('PHOTON EX: $e\n$st');
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
