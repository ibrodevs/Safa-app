import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/date_format_ru.dart';
import '../../../../../core/utils/kg_phone_format.dart';
import '../../../../../core/utils/order_status_view.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/shipment_detail_model.dart';
import '../../data/repo/shipment_detail_repo.dart';
import '../../provider/shipment_detail_provider.dart';
import 'shipment_review_sheet.dart';

class HistoryDetailsScreen extends StatelessWidget {
  const HistoryDetailsScreen({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ShipmentDetailProvider(ShipmentDetailRepository())..load(shipmentId),
      child: _HistoryDetailsBody(shipmentId: shipmentId),
    );
  }
}

class _HistoryDetailsBody extends StatelessWidget {
  const _HistoryDetailsBody({required this.shipmentId});

  final int shipmentId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ShipmentDetailProvider>(
      builder: (context, state, _) {
        if (state.loading && state.detail == null) {
          return const AppScreenScaffold(
            showBackButton: true,
            title: 'Заказ',
            scrollable: false,
            child: AppLoadingState(message: 'Загружаем заказ…'),
          );
        }

        if (state.error != null && state.detail == null) {
          return AppScreenScaffold(
            showBackButton: true,
            title: 'Заказ',
            scrollable: false,
            child: AppErrorState(
              error: state.error,
              title: 'Не удалось загрузить заказ',
              onRetry: () => state.load(shipmentId),
            ),
          );
        }

        return _DetailContent(detail: state.detail!);
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final ShipmentDetail detail;

  String get _numberLabel => detail.publicCode.isNotEmpty
      ? 'Заказ №${detail.publicCode}'
      : 'Заказ #${detail.id}';

  String get _priceLabel {
    if (detail.finalFare > 0) return '${detail.finalFare} сом';
    final estimated = detail.estimatedFare;
    if (estimated != null && estimated > 0) return '$estimated сом';
    return '—';
  }

  String get _commissionLabel {
    final value = int.tryParse(detail.commission) ?? 0;
    return value > 0 ? '${detail.commission} сом' : '—';
  }

  String? get _segmentName {
    final name = detail.segment?['name']?.toString().trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusView.of(detail.status);
    final stops = detail.stops.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return AppScreenScaffold(
      showBackButton: true,
      title: _numberLabel,
      // Действия показываются только те, что имеют смысл для текущего статуса.
      footer: _Actions(status: status, detail: detail),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.title.isEmpty ? 'Без названия' : detail.title,
                  style: AppTypography.sectionTitle,
                ),
              ),
              AppSpacing.hGapXs,
              status.toBadge(),
            ],
          ),
          AppSpacing.gapLg,

          const AppSectionHeader(title: 'Маршрут'),
          AppSpacing.gapXs,
          AppCard(
            child: stops.isEmpty
                ? Text('Маршрут не указан', style: AppTypography.captionMuted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < stops.length; i++)
                        AppRoutePointTile(
                          role: i == 0
                              ? RoutePointRole.start
                              : i == stops.length - 1
                              ? RoutePointRole.end
                              : RoutePointRole.stop,
                          index: (i > 0 && i < stops.length - 1) ? i : null,
                          title: stops[i].displayTitle.isEmpty
                              ? 'Точка ${stops[i].position}'
                              : stops[i].displayTitle,
                          isLast: i == stops.length - 1,
                          dense: true,
                        ),
                    ],
                  ),
          ),
          AppSpacing.gapLg,

          if ((detail.carrierFirstName != null &&
                  detail.carrierFirstName!.isNotEmpty) ||
              (detail.carrierPhone != null &&
                  detail.carrierPhone!.isNotEmpty)) ...[
            const AppSectionHeader(title: 'Специалист'),
            AppSpacing.gapXs,
            AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child:
                          (detail.carrierAvatarUrl != null &&
                              detail.carrierAvatarUrl!.isNotEmpty)
                          ? Image.network(
                              detail.carrierAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CircleAvatar(
                                backgroundColor: AppColors.primarySoft,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.carrierFirstName?.trim().isNotEmpty == true
                              ? detail.carrierFirstName!.trim()
                              : 'Специалист',
                          style: AppTypography.cardTitle,
                        ),
                        if (detail.carrierSpecialistType != null &&
                            detail.carrierSpecialistType!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            detail.carrierSpecialistType == 'cart'
                                ? 'Тачкист'
                                : 'Доставщик',
                            style: AppTypography.captionMuted,
                          ),
                        ],
                        if (detail.carrierPhone != null &&
                            detail.carrierPhone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            formatKgPhone(detail.carrierPhone!.trim()),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (detail.carrierPhone != null &&
                      detail.carrierPhone!.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 20),
                      onPressed: () {
                        final raw = detail.carrierPhone!.replaceAll(
                          RegExp(r'[^\d+]'),
                          '',
                        );
                        if (raw.isNotEmpty) {
                          launchUrl(
                            Uri.parse('tel:$raw'),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapLg,
          ],

          if (detail.review != null) ...[
            const AppSectionHeader(title: 'Ваш отзыв'),
            AppSpacing.gapXs,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= detail.review!.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 25,
                          color: const Color(0xFFFFB020),
                        ),
                      AppSpacing.hGapXs,
                      Text(
                        '${detail.review!.rating}/5',
                        style: AppTypography.cardTitle,
                      ),
                    ],
                  ),
                  if (detail.review!.comment.trim().isNotEmpty) ...[
                    AppSpacing.gapSm,
                    Text(
                      detail.review!.comment.trim(),
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                  AppSpacing.gapXs,
                  Text(
                    formatOrderDateTime(detail.review!.createdAt),
                    style: AppTypography.captionMuted,
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
          ],

          const AppSectionHeader(title: 'О посылке'),
          AppSpacing.gapXs,
          AppCard(
            child: Column(
              children: [
                if (detail.size.isNotEmpty)
                  _InfoRow(
                    icon: Icons.straighten_rounded,
                    label: 'Размер',
                    value: detail.size,
                  ),
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Количество',
                  value: '${detail.quantity}',
                ),
                if (detail.stopsCount.isNotEmpty)
                  _InfoRow(
                    icon: Icons.alt_route_rounded,
                    label: 'Остановок',
                    value: detail.stopsCount,
                  ),
                if (_segmentName != null)
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Тип',
                    value: _segmentName!,
                  ),
                if (detail.description.trim().isNotEmpty)
                  _InfoRow(
                    icon: Icons.description_outlined,
                    label: 'Описание',
                    value: detail.description.trim(),
                  ),
                if (detail.fragile)
                  const _InfoRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Особенность',
                    value: 'Хрупкая посылка',
                    highlight: true,
                    isLast: true,
                  ),
              ],
            ),
          ),
          AppSpacing.gapLg,

          const AppSectionHeader(title: 'Оплата'),
          AppSpacing.gapXs,
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Стоимость заказа',
                  value: _priceLabel,
                  emphasize: true,
                ),
                _InfoRow(
                  icon: Icons.percent_rounded,
                  label: 'Комиссия',
                  value: _commissionLabel,
                ),
                _InfoRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Способ оплаты',
                  value: detail.paidAt != null
                      ? 'Finik · оплачено'
                      : 'Не оплачено',
                  isLast: true,
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,

          const AppSectionHeader(title: 'История статусов'),
          AppSpacing.gapXs,
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Создан',
                  value: formatOrderDateTime(detail.createdAt),
                ),
                if (detail.paidAt != null)
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Оплачен',
                    value: formatOrderDateTime(detail.paidAt!),
                  ),
                if (detail.finishedAt != null)
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Завершён',
                    value: formatOrderDateTime(detail.finishedAt!),
                  ),
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Номер рейса',
                  value: detail.publicCode.isNotEmpty
                      ? detail.publicCode
                      : '${detail.id}',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.status, required this.detail});

  final OrderStatusView status;
  final ShipmentDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.canReview) {
      return AppPrimaryButton(
        label: 'Оставить отзыв',
        icon: Icons.star_rounded,
        onPressed: () async {
          final submitted = await showAppBottomSheet<bool>(
            context: context,
            builder: (_) => ShipmentReviewSheet(shipmentId: detail.id),
          );
          if (submitted == true && context.mounted) {
            await context.read<ShipmentDetailProvider>().load(detail.id);
          }
        },
      );
    }

    if (!status.isActive) return const SizedBox.shrink();

    return AppSecondaryButton(
      label: 'Следить на карте',
      icon: Icons.map_outlined,
      accent: true,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.highlight = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? AppColors.warning : AppColors.textTertiary,
          ),
          AppSpacing.hGapXs,
          Expanded(flex: 4, child: Text(label, style: AppTypography.caption)),
          AppSpacing.hGapXs,
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(
                color: emphasize
                    ? AppColors.primary
                    : highlight
                    ? AppColors.warning
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
