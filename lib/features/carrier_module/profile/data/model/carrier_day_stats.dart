// lib/features/main_module/profile/data/model/carrier_day_stats.dart

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
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    DateTime _asDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    final cp = json['change_percent_vs_prev'];

    return CarrierDayStats(
      date: _asDate(json['date']),
      grossTotal: _asInt(json['gross_total']),
      earned: _asInt(json['earned']),
      commission: _asInt(json['commission']),
      clients: _asInt(json['clients']),
      changePercentVsPrev: cp == null ? null : _asInt(cp),
    );
  }
}
