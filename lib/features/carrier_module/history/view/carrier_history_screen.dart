import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:dogo/core/design/app_colors.dart';
import 'package:dogo/core/utils/order_status_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        strokeWidth: 2.4,
        displacement: 32,
        onRefresh: () => context.read<ShipmentsHistoryProvider>().refresh(),
        child: Consumer<ShipmentsHistoryProvider>(
          builder: (context, state, _) {
            if (state.loading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
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
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                ],
              );
            }

            if (!state.loading && state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
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
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              itemCount: state.items.length + 1 + (state.canLoadMore ? 1 : 0),
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
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final ShipmentHistoryItem item = state.items[itemIndex];

                final numberLabel = item.publicCode.isNotEmpty
                    ? 'Посылка №${item.publicCode}'
                    : 'Посылка #${item.id}';

                final statusText = OrderStatusView.of(item.status).label;

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
                  clientFirstName: item.clientFirstName,
                  clientPhone: item.clientPhone,
                  clientAvatarUrl: item.clientAvatarUrl,
                  onDetails: () {
                    context.push('/history-carrier/detail', extra: item.id);
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
    this.clientFirstName,
    this.clientPhone,
    this.clientAvatarUrl,
  });

  final String numberLabel;
  final String title;
  final String status;
  final List<_HistoryChip> chips;
  final VoidCallback onDetails;
  final String? clientFirstName;
  final String? clientPhone;
  final String? clientAvatarUrl;

  static const _accent = AppColors.primary;
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _statusGreen = Color(0xFF2E7D32);

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

  Widget _clientFallbackAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
    );
  }

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
            if (clientPhone != null && clientPhone!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: (clientAvatarUrl != null &&
                                clientAvatarUrl!.trim().isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: clientAvatarUrl!.trim(),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _clientFallbackAvatar(),
                                errorWidget: (_, __, ___) =>
                                    _clientFallbackAvatar(),
                              )
                            : _clientFallbackAvatar(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  (clientFirstName != null &&
                                          clientFirstName!.trim().isNotEmpty)
                                      ? clientFirstName!.trim()
                                      : 'Клиент',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Клиент',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatKgPhone(clientPhone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      tooltip: 'Позвонить клиенту',
                      onPressed: () async {
                        final clean =
                            clientPhone!.replaceAll(RegExp(r'[^\d+]'), '');
                        if (clean.isNotEmpty) {
                          await launchUrl(
                            Uri.parse('tel:$clean'),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
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
                    padding: EdgeInsets.symmetric(horizontal: 6),
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
