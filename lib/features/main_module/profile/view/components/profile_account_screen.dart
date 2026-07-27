import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../data/services/logout_service.dart';
import '../../provider/profile_provider.dart';

class ProfileAccountScreen extends StatefulWidget {
  const ProfileAccountScreen({super.key});

  static const _accent = AppColors.primary;
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  State<ProfileAccountScreen> createState() => _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends State<ProfileAccountScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();

    final profile = p.profile;
    final loading = p.loading;
    final error = p.error;

    final name = profile == null
        ? '—'
        : (profile.firstName.trim().isEmpty ? '—' : profile.firstName.trim());
    final phone = profile == null
        ? '—'
        : (profile.phoneNumber.trim().isEmpty
              ? '—'
              : profile.phoneNumber.trim());
    final city = profile == null
        ? '—'
        : ((profile.city ?? '').trim().isEmpty
              ? '—'
              : (profile.city ?? '').trim());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Аккаунт',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: ProfileAccountScreen._tileBorder,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error != null) ...[
                      _ErrorCard(
                        text: error,
                        onRetry: () =>
                            context.read<ProfileProvider>().loadProfile(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const Text(
                      'Личные данные',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Используются для регистрации и оформления заказов.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: ProfileAccountScreen._greyText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      child: Column(
                        children: [
                          _AccountTile(
                            label: 'Имя и фамилия',
                            value: name,
                            onTap: profile == null
                                ? null
                                : () => _openEditDialog(
                                    context,
                                    title: 'Имя и фамилия',
                                    hint: 'Введите имя',
                                    initialValue: profile.firstName,
                                    keyboardType: TextInputType.name,
                                    onSave: (v) => context
                                        .read<ProfileProvider>()
                                        .updateProfile(firstName: v.trim()),
                                  ),
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Город',
                            value: city,
                            onTap: profile == null
                                ? null
                                : () => _openEditDialog(
                                    context,
                                    title: 'Город',
                                    hint: 'Введите город',
                                    initialValue: profile.city ?? '',
                                    keyboardType: TextInputType.text,
                                    onSave: (v) => context
                                        .read<ProfileProvider>()
                                        .updateProfile(city: v.trim()),
                                  ),
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Номер телефона',
                            value: phone,
                            onTap: () => _showSnack(
                              context,
                              'Телефон меняется через подтверждение (OTP).',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          _AccountTile(
                            label: 'Выйти из аккаунта',
                            value: 'при выходе все данные сохранятся',
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.red2,
                              fontFamily: 'SFProText',
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            onTap: () => _showLogoutSheet(context),
                            showChevron: false,
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Удалить аккаунт',
                            value: 'данные будут удалены безвозвратно',
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.red2,
                              fontFamily: 'SFProText',
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            onTap: () => _showDeleteAccountSheet(context),
                            showChevron: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutSheet(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _LogoutSheet(),
    );

    if (res != true || !context.mounted) return;

    await const LogoutService().logout();

    if (!context.mounted) return;

    context.go('/');
  }

  Future<void> _showDeleteAccountSheet(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _DeleteAccountSheet(),
    );

    if (res != true || !context.mounted) return;

    final ok = await context.read<ProfileProvider>().deleteAccount();

    if (!context.mounted) return;

    if (ok) {
      await const LogoutService().logout();
      if (!context.mounted) return;
      context.go('/');
    } else {
      final err =
          context.read<ProfileProvider>().error ?? 'Не удалось удалить аккаунт';
      if (!context.mounted) return;
      AppSnackBar.showError(context, message: err);
    }
  }

  Future<void> _openEditDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<bool> Function(String value) onSave,
  }) async {
    String? errorText;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final controller = TextEditingController(text: initialValue);
            final focusNode = FocusNode();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  final saving = ctx.watch<ProfileProvider>().saving;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: saving
                                  ? null
                                  : () => Navigator.of(ctx).pop(false),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: keyboardType,
                          textInputAction: TextInputAction.done,
                          autofocus: true,
                          onChanged: (_) {
                            if (errorText != null) {
                              setState(() => errorText = null);
                            }
                          },
                          onSubmitted: (_) async {
                            if (saving) return;
                            await _trySave(
                              ctx,
                              controller.text,
                              setState,
                              (e) => errorText = e,
                              onSave,
                            );
                          },
                          decoration: InputDecoration(
                            hintText: hint,
                            errorText: errorText,
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: ProfileAccountScreen._tileBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: ProfileAccountScreen._tileBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: ProfileAccountScreen._accent,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.of(ctx).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: ProfileAccountScreen._tileBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Отмена',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          await _trySave(
                                            ctx,
                                            controller.text,
                                            setState,
                                            (e) => errorText = e,
                                            onSave,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        ProfileAccountScreen._accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Сохранить',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
    if (ok == true && context.mounted) {
      AppSnackBar.showSuccess(context, message: 'Сохранено');
    }
  }

  Future<void> _trySave(
    BuildContext ctx,
    String raw,
    void Function(void Function()) setState,
    void Function(String? e) setError,
    Future<bool> Function(String value) onSave,
  ) async {
    final v = raw.trim();
    if (v.isEmpty) {
      setState(() => setError('Поле не может быть пустым'));
      return;
    }

    final ok = await onSave(v);
    if (!ctx.mounted) return;

    if (ok) {
      Navigator.of(ctx).pop(true);
    } else {
      final err = ctx.read<ProfileProvider>().error ?? 'Не удалось сохранить';
      setState(() => setError(err));
    }
  }

  void _showSnack(BuildContext context, String text) {
    AppSnackBar.showSuccess(context, message: text);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileAccountScreen._tileBorder, width: 1),
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
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFCC2B2B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Не удалось загрузить профиль',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A2B2B),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFB5B5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Повторить',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFCC2B2B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E8EA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9EA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE53935),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Выйти из аккаунта?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Мы удалим данные сессии на этом устройстве. Вы сможете войти снова в любое время.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF7B808A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE7E8EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFF111318),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Выйти'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.label,
    required this.value,
    this.valueStyle,
    this.onTap,
    this.showChevron = true,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;
  final bool showChevron;

  static const _greyText = Color(0xFF9FA4AD);
  static const _chev = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        valueStyle ??
                        const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: _greyText,
                        ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded, size: 22, color: _chev),
          ],
        ),
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF2));
  }
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E8EA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9EA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFE53935),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Удалить аккаунт?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Это действие необратимо. Все ваши данные, история и настройки будут удалены навсегда.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF7B808A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE7E8EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFF111318),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Удалить'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
