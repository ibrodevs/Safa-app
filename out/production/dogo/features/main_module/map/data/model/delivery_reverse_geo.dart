class DeliveryReverseGeo {
  final String address;

  const DeliveryReverseGeo({
    required this.address,
  });

  factory DeliveryReverseGeo.fromJson(Map<String, dynamic> json) {
    return DeliveryReverseGeo(
      address: (json['address'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'address': address,
  };
}
