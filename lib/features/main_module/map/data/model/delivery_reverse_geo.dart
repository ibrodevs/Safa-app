import '../../../../../core/utils/address_format.dart';

class DeliveryReverseGeo {
  final String address;

  const DeliveryReverseGeo({required this.address});

  factory DeliveryReverseGeo.fromJson(Map<String, dynamic> json) {
    // Адрес чистим на входе: часть ответов (внешний фолбэк, старый кеш
    // backend) всё ещё приходит с почтовым индексом и страной.
    return DeliveryReverseGeo(
      address: formatReadableAddress(json['address'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {'address': address};
}
