// lib/features/history/history_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// lib/features/main_module/history/components/carrier_history_detail_data.dart
import 'package:flutter/foundation.dart';

class ChipData {
  final String asset;
  final String text;
  const ChipData(this.asset, this.text);
}

class HistoryDetailsData {
  final String titleNumber;
  final String productTitle;
  final List<ChipData> chips;
  final DateTime registeredAt;
  final String routeText;
  final String compositionText;
  final String flightNumber;
  final String statusText;

  const HistoryDetailsData({
    required this.titleNumber,
    required this.productTitle,
    required this.chips,
    required this.registeredAt,
    required this.routeText,
    required this.compositionText,
    required this.flightNumber,
    required this.statusText,
  });
}


class HistoryDetailsScreen extends StatelessWidget {
  const HistoryDetailsScreen({super.key, required this.data});

  final HistoryDetailsData data;

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _statusGreen = Color(0xFF2E7D32);

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy -$hh:$min:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.titleNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.statusText,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: _statusGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: Text(
                data.productTitle,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final chip in data.chips) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          chip.asset,
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            chip.text,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _Divider()),
          SliverToBoxAdapter(child: _Section(title: 'Было зарегистрировано:', value: _fmtDate(data.registeredAt))),
          const SliverToBoxAdapter(child: _Divider()),
          SliverToBoxAdapter(child: _Section(title: 'Маршрут:', value: data.routeText)),
          const SliverToBoxAdapter(child: _Divider()),
          SliverToBoxAdapter(child: _Section(title: 'Составляющие:', value: data.compositionText)),
          const SliverToBoxAdapter(child: _Divider()),
          SliverToBoxAdapter(child: _Section(title: 'Номер рейса', value: data.flightNumber)),
          SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.viewPaddingOf(context).bottom)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});
  final String title;
  final String value;

  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: _greyText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20,10,20,10),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF2)),
    );
  }
}
