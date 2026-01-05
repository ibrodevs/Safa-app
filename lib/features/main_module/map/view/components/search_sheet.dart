import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../data/model/delivery_point_model.dart';

class SearchingSheet extends StatelessWidget {
  const SearchingSheet({
    super.key,
    required this.stops,
    required this.cancelling,
    required this.onCancel,
  });

  final List<DeliveryPoint> stops;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поиск тачкистов',
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < stops.length; i++) ...[
              Text(
                stops[i].title,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stops[i].subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              if (i != stops.length - 1) ...[
                const SizedBox(height: 16),
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 26,
                  color: AppColors.black,
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 24),
              ],
            ],
            const Divider(height: 1, color: AppColors.chev2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  cancelling ? 'Отменяем…' : 'Отменить поиск',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
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
