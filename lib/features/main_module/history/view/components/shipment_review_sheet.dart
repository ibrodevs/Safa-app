import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/friendly_error.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/repo/shipment_detail_repo.dart';

class ShipmentReviewSheet extends StatefulWidget {
  const ShipmentReviewSheet({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  State<ShipmentReviewSheet> createState() => _ShipmentReviewSheetState();
}

class _ShipmentReviewSheetState extends State<ShipmentReviewSheet> {
  final _commentController = TextEditingController();
  final _repository = ShipmentDetailRepository();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Выберите оценку от 1 до 5 звёзд');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.submitReview(
        widget.shipmentId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(
          error,
          fallback: 'Не удалось оставить отзыв',
        );
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Оставить отзыв',
      subtitle: 'Оцените работу специалиста по пятибалльной шкале',
      footer: AppPrimaryButton(
        label: 'Оставить отзыв',
        loadingLabel: 'Отправляем…',
        loading: _submitting,
        enabled: _rating > 0,
        onPressed: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: _rating == 0 ? 'Оценка не выбрана' : 'Оценка $_rating из 5',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                final selected = value <= _rating;
                return IconButton(
                  tooltip: '$value из 5',
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                          _rating = value;
                          _error = null;
                        }),
                  iconSize: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: selected
                        ? const Color(0xFFFFB020)
                        : AppColors.borderStrong,
                  ),
                );
              }),
            ),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Комментарий (необязательно)',
              hintText: 'Расскажите, как прошёл заказ',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          AppFormError(message: _error),
        ],
      ),
    );
  }
}
