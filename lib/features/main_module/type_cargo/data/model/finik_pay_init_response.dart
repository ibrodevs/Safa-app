final class FinikPayInitResponse {
  final String paymentId;
  final String finikRequestId;
  final String callbackUrl;
  final Map<String, dynamic> requiredFields;
  final num amount;
  final String currency;

  const FinikPayInitResponse({
    required this.paymentId,
    required this.finikRequestId,
    required this.callbackUrl,
    required this.requiredFields,
    required this.amount,
    required this.currency,
  });

  factory FinikPayInitResponse.fromJson(Map<String, dynamic> json) {
    return FinikPayInitResponse(
      paymentId: (json['paymentId'] ?? '').toString(),
      finikRequestId: (json['finikRequestId'] ?? '').toString(),
      callbackUrl: (json['callbackUrl'] ?? '').toString(),
      requiredFields: (json['requiredFields'] is Map)
          ? Map<String, dynamic>.from(json['requiredFields'] as Map)
          : <String, dynamic>{},
      amount: (json['amount'] is num) ? (json['amount'] as num) : num.tryParse((json['amount'] ?? '').toString()) ?? 0,
      currency: (json['currency'] ?? 'KGS').toString(),
    );
  }
}
