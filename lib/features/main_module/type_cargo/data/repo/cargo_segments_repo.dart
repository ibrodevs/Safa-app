
import '../../../../../data/network/api_service.dart';
import '../model/cargo_segment_model.dart';

class CargoSegmentsRepository {
  CargoSegmentsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<List<CargoSegment>> getSegments() {
    return _api.getDeliverySegments();
  }
}
