
import '../../../../../data/network/api_service.dart';
import '../model/shipment_history_models.dart';

class ShipmentsHistoryRepository {
  final ApiService _api;

  ShipmentsHistoryRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ShipmentHistoryPage> fetchPage({
    required int page,
    required int pageSize,
  }) {
    return _api.getShipmentHistory(page: page, pageSize: pageSize);
  }
}
