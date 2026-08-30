import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/order_status_view.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/delivery_point_model.dart';
import 'map_panel_shell.dart';

/// Панель «заказ выполняется» над картой.
class OrderFulfillmentSheet extends StatelessWidget {
  const OrderFulfillmentSheet({
    super.key,
    required this.stops,
    this.statusCode = 'in_transit',
    this.carrierFirstName,
    this.carrierPhone,
    this.carrierAvatarUrl,
    this.carrierSpecialistType,
  });

  final List<DeliveryPoint> stops;

  /// Код статуса с backend — определяет текст и цвет бейджа.
  final String statusCode;

  final String? carrierFirstName;
  final String? carrierPhone;
  final String? carrierAvatarUrl;
  final String? carrierSpecialistType;

  Future<void> _callCarrier(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось набрать номер $phone')),
      );
    }
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 12 && digits.startsWith('996')) {
      return '+996\u00A0(${digits.substring(3, 6)})\u00A0${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return raw.replaceAll(' ', '\u00A0');
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
    );
  }

  String _titleForStop(DeliveryPoint s) {
    final container = (s.container ?? '').trim();
    final passage = (s.passage ?? '').trim();

    if (container.isNotEmpty && passage.isNotEmpty) {
      return 'Контейнер $container, проход $passage';
    }
    if (container.isNotEmpty) return 'Контейнер $container';
    if (passage.isNotEmpty) return 'Проход $passage';

    return s.title;
  }

  String _subtitleForStop(DeliveryPoint s) {
    final bazar = (s.bazar ?? '').trim();
    return bazar.isNotEmpty ? bazar : s.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    final status = OrderStatusView.of(statusCode);
    final name = (carrierFirstName ?? '').trim().isNotEmpty
        ? carrierFirstName!.trim()
        : 'Специалист';
    final phone = (carrierPhone ?? '').trim();
    final roleLabel = carrierSpecialistType == 'cart'
        ? 'Тачкист'
        : (carrierSpecialistType == 'delivery' ? 'Доставщик' : 'Специалист');
    final hasCarrier = (carrierFirstName != null && carrierFirstName!.isNotEmpty) ||
        (carrierPhone != null && carrierPhone!.isNotEmpty);

    return MapPanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ выполняется',
                  style: AppTypography.cardTitle,
                ),
              ),
              AppSpacing.hGapXs,
              status.toBadge(dense: true),
            ],
          ),
          AppSpacing.gapMd,
          if (hasCarrier) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: (carrierAvatarUrl != null &&
                              carrierAvatarUrl!.isNotEmpty)
                          ? Image.network(
                              carrierAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2E8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatPhone(phone),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(42, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _callCarrier(context, phone),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text(
                        'Звонок',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapMd,
          ],
          for (var i = 0; i < stops.length; i++)
            AppRoutePointTile(
              role: i == 0
                  ? RoutePointRole.start
                  : i == stops.length - 1
                  ? RoutePointRole.end
                  : RoutePointRole.stop,
              index: (i > 0 && i < stops.length - 1) ? i : null,
              title: _titleForStop(stops[i]),
              subtitle: _subtitleForStop(stops[i]),
              isLast: i == stops.length - 1,
              dense: true,
              trailing: i == 0
                  ? const AppStatusBadge(
                      label: 'Вы здесь',
                      tone: AppBadgeTone.success,
                      icon: Icons.person_pin_circle_outlined,
                      dense: true,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
