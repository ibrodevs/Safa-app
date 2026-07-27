import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Тема приложения (Material 3).
///
/// Раньше тема строилась из `ColorScheme.fromSeed(seedColor: Colors.orange)`
/// и почти не использовалась, потому что каждый виджет задавал цвета вручную.
/// Здесь схема собрана из фирменной палитры, а компоненты Material настроены
/// так, чтобы стандартные `ElevatedButton`, `TextField`, `AppBar` и
/// `BottomNavigationBar` выглядели правильно без ручной стилизации.
class AppTheme {
  const AppTheme._();

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryPressed,
    secondary: AppColors.info,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.infoSoft,
    onSecondaryContainer: AppColors.info,
    tertiary: AppColors.success,
    onTertiary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorSoft,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceMuted,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.borderStrong,
    shadow: AppColors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.white,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allLg,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.surfaceMuted,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTypography.button.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          textStyle: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        hintStyle: AppTypography.fieldHint,
        labelStyle: AppTypography.label,
        helperStyle: AppTypography.captionMuted,
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.primary, width: 1.6),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error, width: 1.6),
        disabledBorder: _fieldBorder(AppColors.border),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTypography.badge,
        unselectedLabelStyle: AppTypography.badge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        titleTextStyle: AppTypography.sectionTitle,
        contentTextStyle: AppTypography.bodySecondary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        elevation: 0,
        contentTextStyle: AppTypography.body,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceMuted,
        circularTrackColor: AppColors.surfaceMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide.none,
        labelStyle: AppTypography.badge,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: AppTypography.cardTitle,
        subtitleTextStyle: AppTypography.caption,
        minVerticalPadding: AppSpacing.sm,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.cardTitle,
        unselectedLabelStyle: AppTypography.body,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.allMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: AppTypography.screenTitle,
      displayMedium: AppTypography.screenTitle,
      displaySmall: AppTypography.screenTitleCompact,
      headlineLarge: AppTypography.screenTitle,
      headlineMedium: AppTypography.screenTitleCompact,
      headlineSmall: AppTypography.sectionTitle,
      titleLarge: AppTypography.sectionTitle,
      titleMedium: AppTypography.cardTitle,
      titleSmall: AppTypography.cardTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button.copyWith(color: AppColors.textPrimary),
      labelMedium: AppTypography.label,
      labelSmall: AppTypography.badge,
    );
  }
}
