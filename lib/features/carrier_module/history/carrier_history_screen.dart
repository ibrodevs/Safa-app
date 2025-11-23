// lib/features/history/carrier_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import 'components/carrier_history_detail_data.dart';

class CarrierHistoryScreen extends StatelessWidget {
  const CarrierHistoryScreen({super.key});

  static const _accent = Color(0xFFE67E22);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _statusGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'История',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              _HistoryCard(
                numberLabel: 'Посылка №2',
                title: 'Sony playstation 5',
                status: 'Завершено',
                chips: const [
                  _HistoryChip(asset: 'assets/icons/ic_box.svg', text: 'Большие коробки'),
                  _HistoryChip(asset: 'assets/icons/ic_weight.svg', text: '6 коробок'),
                  _HistoryChip(asset: 'assets/icons/ic_warning.svg', text: 'Хрупкая посылка'),
                ],
                onDetails: () {
                  final data = CarrierHistoryDetailsData(
                    titleNumber: 'Посылка №1',
                    productTitle: 'Sony playstation 5',
                    chips: const [
                      CarrierChipData('assets/icons/ic_box.svg', 'Большие коробки'),
                      CarrierChipData('assets/icons/ic_weight.svg', '6 коробок'),
                    ],
                    registeredAt: DateTime(2025, 9, 21, 14, 7, 27),
                    routeText: 'Контейнер 74, 8 проход /\nКонтейнер 78, 1 проход /\nКонтейнер 91, 6 проход',
                    compositionText: '5 мешков больших',
                    flightNumber: '1556',
                    statusText: 'Завершено',
                  );
                  context.push('/history/detail', extra: data);
                },
              ),
              const SizedBox(height: 18),

              _HistoryCard(
                numberLabel: 'Посылка №1',
                title: 'Sony playstation 5',
                status: 'Завершено',
                chips: const [
                  _HistoryChip(asset: 'assets/icons/ic_box.svg', text: 'Большие коробки'),
                  _HistoryChip(asset: 'assets/icons/ic_weight.svg', text: '6 коробок'),
                ],
                onDetails: () {
                  final data = CarrierHistoryDetailsData(
                    titleNumber: 'Посылка №1',
                    productTitle: 'Sony playstation 5',
                    chips: const [
                      CarrierChipData('assets/icons/ic_box.svg', 'Большие коробки'),
                      CarrierChipData('assets/icons/ic_weight.svg', '6 коробок'),
                    ],
                    registeredAt: DateTime(2025, 9, 21, 14, 7, 27),
                    routeText: 'Контейнер 74, 8 проход /\nКонтейнер 78, 1 проход /\nКонтейнер 91, 6 проход',
                    compositionText: '5 мешков больших',
                    flightNumber: '1556',
                    statusText: 'Завершено',
                  );
                  context.push('/history/detail', extra: data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.numberLabel,
    required this.title,
    required this.status,
    required this.chips,
    required this.onDetails,
  });

  final String numberLabel;
  final String title;
  final String status;
  final List<_HistoryChip> chips;
  final VoidCallback onDetails;

  static const _accent = Color(0xFFE67E22);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _statusGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _tileBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    numberLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: _greyText,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: _statusGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),

            for (final chip in chips) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    chip.asset,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chip.text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Подробнее',style: TextStyle(color: Colors.black),),
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


class _HistoryChip {
  final String asset;
  final String text;
  const _HistoryChip({required this.asset, required this.text});
}