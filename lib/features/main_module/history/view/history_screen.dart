import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/utils/date_format_ru.dart';
import '../../../../core/utils/order_status_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../data/model/shipment_history_models.dart';
import '../data/repo/shipments_history_repo.dart';
import '../provider/shipments_history_provider.dart';
import 'components/order_filter_tabs.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
  OrderFilter _filter = OrderFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

  Map<OrderFilter, int> _countsFor(List<ShipmentHistoryItem> items) {
    return {
      for (final filter in OrderFilter.values)
        filter: items.where((i) => filter.matches(i.status)).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = AppResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<ShipmentsHistoryProvider>(
          builder: (context, state, _) {
            final visible = state.items
                .where((item) => _filter.matches(item.status))
                .toList();

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              strokeWidth: 2.4,
              displacement: 32,
              onRefresh: () => state.refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      AppSpacing.xs,
                      horizontal,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppContentWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Мои заказы',
                              style: AppResponsive.useCompactTitle(context)
                                  ? AppTypography.screenTitleCompact
                                  : AppTypography.screenTitle,
                            ),
                            AppSpacing.gapMd,
                            OrderFilterTabs(
                              selected: _filter,
                              counts: _countsFor(state.items),
                              onChanged: (filter) =>
                                  setState(() => _filter = filter),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._buildContent(state, visible, horizontal),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ShipmentsHistoryProvider state,
    List<ShipmentHistoryItem> visible,
    double horizontal,
  ) {
    final padding = EdgeInsets.fromLTRB(
      horizontal,
      0,
      horizontal,
      AppSpacing.xl,
    );

    // Загрузка первой страницы — skeleton, а не бесконечный спиннер
    // на весь экран.
    if (state.loading && state.items.isEmpty) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: AppContentWidth(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    const AppOrderCardSkeleton(),
                    if (i != 2) AppSpacing.gapSm,
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (state.error != null && state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            error: state.error,
            title: 'Не удалось загрузить заказы',
            onRetry: state.refresh,
          ),
        ),
      ];
    }

    if (visible.isEmpty) {
      final isFiltered = _filter != OrderFilter.all && state.items.isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: isFiltered
              ? AppEmptyState(
                  title: 'Нет заказов в этой категории',
                  message: 'Попробуйте выбрать другой фильтр',
                  icon: Icons.filter_alt_outlined,
                  actionLabel: 'Показать все',
                  onAction: () => setState(() => _filter = OrderFilter.all),
                )
              : AppEmptyState(
                  title: 'Заказов пока нет',
                  message:
                      'Оформите первый заказ — он появится здесь '
                      'вместе со статусом',
                  icon: Icons.local_shipping_outlined,
                  actionLabel: 'Создать заказ',
                  onAction: () => context.go('/home'),
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: AppContentWidth(
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _buildCard(visible[i]),
                  if (i != visible.length - 1) AppSpacing.gapSm,
                ],
                if (state.canLoadMore) ...[
                  AppSpacing.gapMd,
                  const AppLoadingState(
                    message: 'Загружаем ещё заказы…',
                    compact: true,
                  ),
                ],
                if (state.error != null && state.items.isNotEmpty) ...[
                  AppSpacing.gapMd,
                  AppFormError(message: state.error),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCard(ShipmentHistoryItem item) {
    final stopsCount = int.tryParse(item.stopsCount);
    final price = item.estimatedFare > 0 ? '${item.estimatedFare} сом' : null;

    return AppOrderCard(
      number: item.publicCode.isNotEmpty
          ? 'Заказ №${item.publicCode}'
          : 'Заказ #${item.id}',
      title: item.title.isNotEmpty ? item.title : 'Без названия',
      status: OrderStatusView.of(item.status),
      date: formatOrderDate(item.createdAt),
      serviceLabel: item.quantity > 0 ? 'Мест: ${item.quantity}' : null,
      serviceIcon: Icons.inventory_2_outlined,
      stopsCount: stopsCount,
      priceLabel: price,
      onTap: () => context.push('/history/detail', extra: item.id),
    );
  }
}
