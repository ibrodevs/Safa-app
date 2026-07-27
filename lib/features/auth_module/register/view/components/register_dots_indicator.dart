import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';

/// Индикатор шагов регистрации.
///
/// Раньше активная точка искалась через `findAncestorWidgetOfExactType`
/// и красилась в отдельный оранжевый `#E67E22`. Теперь состояние
/// передаётся напрямую, цвет берётся из палитры, а активная точка
/// анимируется по ширине (200 ms).
class RegisterDotsIndicator extends StatelessWidget {
  const RegisterDotsIndicator({
    super.key,
    required this.activeIndex,
    this.count = 3,
  });

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Шаг ${activeIndex + 1} из $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOut,
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? AppColors.primary
                    : AppColors.borderStrong,
                borderRadius: AppRadius.allFull,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
