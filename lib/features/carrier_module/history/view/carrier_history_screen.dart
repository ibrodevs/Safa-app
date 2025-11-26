import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../main_module/history/data/model/shipment_history_models.dart';
import '../../../main_module/history/data/repo/shipments_history_repo.dart';
import '../../../main_module/history/provider/shipments_history_provider.dart';

class CarrierHistoryScreen extends StatelessWidget {
  const CarrierHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ShipmentsHistoryProvider(ShipmentsHistoryRepository())..refresh(),
      child: const _HistoryBody(),
    );
  }
}

class _HistoryBody extends StatefulWidget {
  const _HistoryBody();

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<ShipmentsHistoryProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        provider.canLoadMore &&
        !provider.loadingMore &&
        !provider.loading) {
      provider.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: const Color(0xFFE67E22),
        backgroundColor: Colors.white,
        strokeWidth: 2.4,
        displacement: 32,
        onRefresh: () =>
            context.read<ShipmentsHistoryProvider>().refresh(),
        child: Consumer<ShipmentsHistoryProvider>(
          builder: (context, state, _) {
            if (state.loading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
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
                  const SizedBox(height: 40),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              );
            }

            if (!state.loading && state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                children: const [
                  Text(
                    'История',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 40),
                  _EmptyHistoryPlaceholder(),
                ],
              );
            }

            return ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              itemCount:
              state.items.length + 1 + (state.canLoadMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Text(
                    'История',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  );
                }

                final itemIndex = index - 1;

                if (itemIndex >= state.items.length) {
                  if (!state.canLoadMore) {
                    return const SizedBox.shrink();
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  );
                }

                final ShipmentHistoryItem item = state.items[itemIndex];

                final numberLabel = item.publicCode.isNotEmpty
                    ? 'Посылка №${item.publicCode}'
                    : 'Посылка #${item.id}';

                final statusText = _mapStatus(item.status);

                final chips = <_HistoryChip>[
                  _HistoryChip(
                    asset: 'assets/icons/ic_box.svg',
                    text: 'Количество: ${item.quantity}',
                  ),
                  if (item.stopsCount.isNotEmpty)
                    _HistoryChip(
                      asset: 'assets/icons/ic_weight.svg',
                      text: 'Остановок: ${item.stopsCount}',
                    ),
                  if (item.fragile)
                    const _HistoryChip(
                      asset: 'assets/icons/ic_warning.svg',
                      text: 'Хрупкая посылка',
                    ),
                ];

                return _HistoryCard(
                  numberLabel: numberLabel,
                  title: item.title,
                  status: statusText,
                  chips: chips,
                  onDetails: () {
                    context.push(
                      '/history/detail',
                      extra: item.id,
                    );
                  },
                );
              },
            );
          },
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
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
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
                    colorFilter: const ColorFilter.mode(
                      _accent,
                      BlendMode.srcIn,
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Подробнее',
                      style: TextStyle(color: Colors.black),
                    ),
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

class _EmptyHistoryPlaceholder extends StatelessWidget {
  const _EmptyHistoryPlaceholder();

  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'У вас пока нет посылок',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: _greyText,
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
