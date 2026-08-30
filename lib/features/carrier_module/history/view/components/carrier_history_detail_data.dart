import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:dogo/core/design/app_colors.dart';
import 'package:dogo/core/utils/order_status_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main_module/history/data/model/shipment_detail_model.dart';
import '../../../../main_module/history/data/repo/shipment_detail_repo.dart';
import '../../../../main_module/history/provider/shipment_detail_provider.dart';

class CarrierHistoryDetailsScreen extends StatelessWidget {
  const CarrierHistoryDetailsScreen({super.key, required this.shipmentId});

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

  static const _accent = AppColors.primary;

  String _fmtDate(DateTime d) {
    try {
      return DateFormat('dd.MM.yyyy - HH:mm:ss').format(d);
    } catch (_) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString().padLeft(4, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      final ss = d.second.toString().padLeft(2, '0');
      return '$dd.$mm.$yyyy -$hh:$min:$ss';
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
              padding: EdgeInsets.only(top: top + 32, left: 24, right: 24),
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
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }

        final ShipmentDetail d = state.detail!;
        final titleNumber = d.publicCode.isNotEmpty
            ? 'Посылка №${d.publicCode}'
            : 'Посылка #${d.id}';
        final statusView = OrderStatusView.of(d.status);
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
            const _DetailChip('assets/icons/ic_warning.svg', 'Хрупкая посылка'),
          if (d.segment != null &&
              (d.segment!['name']?.toString() ?? '').isNotEmpty)
            _DetailChip(
              'assets/icons/ic_box.svg',
              'Тип: ${d.segment!['name']}',
            ),
        ];
        final flightNumberText = d.publicCode.isNotEmpty
            ? d.publicCode
            : d.id.toString();

        final orderCostText = (d.finalFare > 0)
            ? '${d.finalFare} сом'
            : (d.estimatedFare != null && d.estimatedFare! > 0)
            ? '${d.estimatedFare} сом'
            : '—';

        final commissionValue = int.tryParse(d.commission) ?? 0;
        final commissionText = (d.commission.isNotEmpty && commissionValue > 0)
            ? '${d.commission} сом'
            : '—';

        final routeText = d.stops.isEmpty
            ? 'Маршрут не указан'
            : d.stops.map((s) => '${s.position}. ${s.displayTitle}').join('\n');

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
        // ignore: unused_local_variable\r\n        final priceText = priceBuffer.toString().trim();

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
                      statusView.toBadge(dense: true),
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
              if (d.clientPhone != null && d.clientPhone!.trim().isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ClientDetailCard(
                      name: d.clientFirstName,
                      phone: d.clientPhone!.trim(),
                      avatarUrl: d.clientAvatarUrl,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Было зарегистрировано:',
                  value: _fmtDate(d.createdAt),
                ),
              ),
              if (d.paidAt != null) ...[
                const SliverToBoxAdapter(child: _Divider()),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Оплачено:',
                    value: _fmtDate(d.paidAt!),
                  ),
                ),
              ],
              if (d.finishedAt != null) ...[
                const SliverToBoxAdapter(child: _Divider()),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Завершено:',
                    value: _fmtDate(d.finishedAt!),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(title: 'Маршрут:', value: routeText),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(title: 'Составляющие:', value: compositionText),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(title: 'Номер рейса', value: flightNumberText),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Стоимость заказа',
                  value: orderCostText,
                ),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Стоимость комиссий',
                  value: commissionText,
                ),
              ),
              const SliverToBoxAdapter(child: _Divider()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => context.push('/profile/support'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: _accent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      child: const Text('Связаться с поддержкой'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 32 + MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
            ],
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
      padding: EdgeInsets.fromLTRB(20, 2, 20, 2),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF2)),
    );
  }
}

class _DetailChip {
  final String asset;
  final String text;

  const _DetailChip(this.asset, this.text);
}

class _ClientDetailCard extends StatelessWidget {
  const _ClientDetailCard({
    this.name,
    required this.phone,
    this.avatarUrl,
  });

  final String? name;
  final String phone;
  final String? avatarUrl;

  String _formatKgPhone(String? input) {
    if (input == null) return '—';
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '—';
    if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }
    if (digits.length == 9) {
      digits = '996$digits';
    }
    if (digits.length == 12 && digits.startsWith('996')) {
      final op = digits.substring(3, 6);
      final a = digits.substring(6, 8);
      final b = digits.substring(8, 10);
      final c = digits.substring(10, 12);
      return '+996 $op $a-$b-$c';
    }
    return input.trim().startsWith('+') ? input.trim() : '+$digits';
  }

  Widget _avatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Future<void> _makeCall(BuildContext context) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось набрать номер $phone')),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть WhatsApp для $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : 'Клиент';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 44,
              height: 44,
              child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!.trim(),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarFallback(),
                      placeholder: (_, __) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Клиент',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _formatKgPhone(phone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 17),
            tooltip: 'WhatsApp',
            onPressed: () => _openWhatsApp(context),
          ),
          const SizedBox(width: 6),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.phone_rounded, size: 18),
            tooltip: 'Позвонить',
            onPressed: () => _makeCall(context),
          ),
        ],
      ),
    );
  }
}
