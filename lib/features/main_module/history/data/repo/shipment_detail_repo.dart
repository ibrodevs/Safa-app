import '../../../../../data/network/api_service.dart';
import '../model/shipment_detail_model.dart';

class ShipmentDetailRepository {
  final ApiService _api;

  ShipmentDetailRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ShipmentDetail> fetchDetail(int id) {
    return _api.getShipmentDetail(id);
  }
}
