import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/model/shipment_detail_model.dart';
import '../../data/repo/shipment_detail_repo.dart';
import '../../provider/shipment_detail_provider.dart';

class HistoryDetailsScreen extends StatelessWidget {
  const HistoryDetailsScreen({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ShipmentDetailProvider(ShipmentDetailRepository())..load(shipmentId),
      child: const _HistoryDetailsBody(),
    );
  }
}

class _HistoryDetailsBody extends StatelessWidget {
  const _HistoryDetailsBody();

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
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

  String _mapStatus(String code) {
    switch (code) {
      case 'pending':
        return 'В обработке';
      case 'accepted':
        return 'Принято';
      case 'in_progress':
        return 'В пути';
      case 'completed':
      case 'delivered':
        return 'Завершено';
      case 'canceled':
        return 'Отменено';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;

    return Consumer<ShipmentDetailProvider>(
      builder: (context, state, _) {
        if (state.loading && state.detail == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: EdgeInsets.only(top: top + 32),
                child: const CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state.error != null && state.detail == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: EdgeInsets.only(
                top: top + 32,
                left: 24,
                right: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final ShipmentDetail d = state.detail!;

        final titleNumber = d.publicCode.isNotEmpty
            ? 'Посылка №${d.publicCode}'
            : 'Посылка #${d.id}';
        final statusText = _mapStatus(d.status);

        final chips = <_DetailChip>[
          _DetailChip(
            'assets/icons/ic_box.svg',
            'Размер: ${d.size}, кол-во: ${d.quantity}',
          ),
          if (d.stopsCount.isNotEmpty)
            _DetailChip(
              'assets/icons/ic_weight.svg',
              'Остановок: ${d.stopsCount}',
            ),
          if (d.fragile)
            const _DetailChip(
              'assets/icons/ic_warning.svg',
              'Хрупкая посылка',
            ),
          if (d.segment != null && d.segment!.name.isNotEmpty)
            _DetailChip(
              'assets/icons/ic_box.svg',
              'Тип: ${d.segment!.name}',
            ),
        ];

        final routeText = d.stops.isEmpty
            ? 'Маршрут не указан'
            : d.stops
            .map(
              (s) => '${s.position}. ${s.title}',
        )
            .join('\n');

        final compositionBuffer = StringBuffer();
        if (d.description.isNotEmpty) {
          compositionBuffer.writeln(d.description);
        }
        compositionBuffer.writeln('Размер: ${d.size}');
        compositionBuffer.writeln('Количество: ${d.quantity}');
        if (d.fragile) {
          compositionBuffer.writeln('Хрупкая посылка');
        }
        final compositionText = compositionBuffer.toString().trim();

        final priceBuffer = StringBuffer();
        priceBuffer.writeln('Предварительная стоимость: ${d.estimatedFare}');
        priceBuffer.writeln('Итоговая стоимость: ${d.finalFare}');
        if (d.courierIncome.isNotEmpty) {
          priceBuffer.writeln('Доход курьера: ${d.courierIncome}');
        }
        if (d.commission.isNotEmpty) {
          priceBuffer.writeln('Комиссия: ${d.commission}');
        }
        final priceText = priceBuffer.toString().trim();

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
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          titleNumber,
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
                        statusText,
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
                    d.title,
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
                      for (final chip in chips) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              chip.asset,
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                _accent,
                                BlendMode.srcIn,
                              ),
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
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Было зарегистрировано:',
                  value: _fmtDate(d.createdAt),
                ),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Маршрут:',
                  value: routeText,
                ),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Составляющие:',
                  value: compositionText,
                ),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Стоимость и код заказа:',
                  value: d.publicCode.isNotEmpty
                      ? 'Код: ${d.publicCode}\n$priceText'
                      : priceText,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                  32 + MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
            ],
          ),

          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, -6),
                    color: Color(0x14000000),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/profile/support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Поддержка'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE9EDF2),
      ),
    );
  }
}

class _DetailChip {
  final String asset;
  final String text;

  const _DetailChip(this.asset, this.text);
}
