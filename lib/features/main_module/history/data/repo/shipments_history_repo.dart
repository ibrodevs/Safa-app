import '../../../../../data/network/api_service.dart';
import '../model/shipment_history_models.dart';

class ShipmentsHistoryRepository {
  final ApiService _api;

  ShipmentsHistoryRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ShipmentHistoryPage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    final json = await _api.getShipments(page: page, pageSize: pageSize);
    return ShipmentHistoryPage.fromJson(json);
  }
}
