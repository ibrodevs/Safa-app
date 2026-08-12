import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/friendly_error.dart';
import '../../../../../data/network/api_service.dart';

class ProfileBalanceHistoryScreen extends StatefulWidget {
  const ProfileBalanceHistoryScreen({super.key});

  @override
  State<ProfileBalanceHistoryScreen> createState() =>
      _ProfileBalanceHistoryScreenState();
}

class _ProfileBalanceHistoryScreenState
    extends State<ProfileBalanceHistoryScreen> {
  bool _loading = true;
  String? _error;
  int _balance = 0;
  String _currency = 'KGS';
  List<Map<String, dynamic>> _settlements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.dio.get(
        'payments/carrier/wallet/',
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      final list = raw['settlements'] is List
          ? raw['settlements'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _balance = (raw['balance'] as num?)?.toInt() ?? 0;
        _currency = (raw['currency'] ?? 'KGS').toString();
        _settlements = list
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = friendlyErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Баланс и начисления')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Подтверждённые начисления',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_balance $_currency',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Баланс формируется только после подтверждённой оплаты Finik.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(_error!, textAlign: TextAlign.center))
            else if (_settlements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Начислений пока нет',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              for (final settlement in _settlements)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                    ),
                    title: Text(
                      'Заказ №${settlement['shipment_code'] ?? settlement['shipment']}',
                    ),
                    subtitle: Text(
                      'Оплачено через Finik · комиссия ${settlement['commission_amount'] ?? 0} $_currency',
                    ),
                    trailing: Text(
                      '+${settlement['net_amount'] ?? 0} $_currency',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
