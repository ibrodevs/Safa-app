import 'package:dogo/data/network/api_service.dart';

import 'amanat_models.dart';

class AmanatRepository {
  AmanatRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<List<AmanatCategory>> loadCategories() async {
    final resp = await _api.dio.get<dynamic>('delivery/amanat/categories/');
    final data = resp.data;
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((e) => AmanatCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AmanatCampaign>> loadCampaigns({String? categorySlug}) async {
    final resp = await _api.dio.get<dynamic>(
      'delivery/amanat/campaigns/',
      queryParameters: {
        if (categorySlug != null && categorySlug.isNotEmpty)
          'category': categorySlug,
        'page_size': 100,
      },
    );
    final data = resp.data;
    final raw = data is Map ? data['results'] : data;
    final list = raw is List ? raw : const [];
    return list
        .whereType<Map>()
        .map((e) => AmanatCampaign.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AmanatCampaign> loadCampaign(int id) async {
    final resp = await _api.dio.get<dynamic>('delivery/amanat/campaigns/$id/');
    return AmanatCampaign.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }
}
