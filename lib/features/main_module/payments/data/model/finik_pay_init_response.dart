class FinikPayInitResponse {
  final String paymentId;
  final String finikRequestId;
  final String callbackUrl;
  final num amount;
  final String currency;
  final Map<String, dynamic> requiredFields;

  const FinikPayInitResponse({
    required this.paymentId,
    required this.finikRequestId,
    required this.callbackUrl,
    required this.amount,
    required this.currency,
    required this.requiredFields,
  });

  factory FinikPayInitResponse.fromJson(Map<String, dynamic> j) {
    return FinikPayInitResponse(
      paymentId: (j['paymentId'] ?? j['payment_id'])?.toString() ?? '',
      finikRequestId:
          (j['finikRequestId'] ?? j['finik_request_id'])?.toString() ?? '',
      callbackUrl: (j['callbackUrl'] ?? j['callback_url'])?.toString() ?? '',
      amount: j['amount'] is num ? (j['amount'] as num) : 0,
      currency: j['currency']?.toString() ?? 'KGS',
      requiredFields: (j['requiredFields'] ?? j['required_fields']) is Map
          ? Map<String, dynamic>.from(
              j['requiredFields'] ?? j['required_fields'],
            )
          : const {},
    );
  }
}
