class CarrierDayStats {
  final DateTime date;
  final int grossTotal;
  final int earned;
  final int commission;
  final int clients;
  final int? changePercentVsPrev;

  CarrierDayStats({
    required this.date,
    required this.grossTotal,
    required this.earned,
    required this.commission,
    required this.clients,
    required this.changePercentVsPrev,
  });

  factory CarrierDayStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    DateTime asDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    final cp = json['change_percent_vs_prev'];

    return CarrierDayStats(
      date: asDate(json['date']),
      grossTotal: asInt(json['gross_total']),
      earned: asInt(json['earned']),
      commission: asInt(json['commission']),
      clients: asInt(json['clients']),
      changePercentVsPrev: cp == null ? null : asInt(cp),
    );
  }
}
