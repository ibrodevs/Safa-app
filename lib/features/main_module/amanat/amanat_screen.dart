import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dogo/core/design/app_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../payments/provider/finik_payment_flow_provider.dart';
import 'amanat_models.dart';
import 'amanat_provider.dart';

const String _amanatHomeTitle = 'Аманат';
const String _medreseDonationTitle = 'Пожертвование на Медресе';

class AmanatScreen extends StatelessWidget {
  const AmanatScreen({super.key});

  static const String route = '/amanat';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(bottom: false, child: _AmanatHomeBody()),
    );
  }
}

class AmanatDetailScreen extends StatelessWidget {
  const AmanatDetailScreen({super.key, required this.campaignId});

  static const String route = '/amanat/detail';

  final int campaignId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: _AmanatDetailBody(campaignId: campaignId),
      ),
    );
  }
}

class _AmanatHomeBody extends StatefulWidget {
  const _AmanatHomeBody();

  @override
  State<_AmanatHomeBody> createState() => _AmanatHomeBodyState();
}

class _AmanatHomeBodyState extends State<_AmanatHomeBody> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AmanatProvider>();
    Future.microtask(() {
      provider.load();
      provider.startLiveUpdates();
    });
  }

  @override
  void dispose() {
    context.read<AmanatProvider>().stopLiveUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmanatProvider>();
    final campaigns = state.campaigns;
    final featured = state.featuredCampaign;
    final bottomSafe = math.max(MediaQuery.viewPaddingOf(context).bottom, 16.0);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AmanatProvider>().load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(15, 9, 15, 28 + bottomSafe),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - (37 + bottomSafe)).clamp(0.0, double.infinity),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AmanatHeader(title: _amanatHomeTitle),
                  const SizedBox(height: 24),
                  if (state.loading && campaigns.isEmpty)
                    const _AmanatLoadingBlock()
                  else if (state.error != null && campaigns.isEmpty)
                    _AmanatErrorState(
                      message: state.error!,
                      onRetry: () => context.read<AmanatProvider>().load(),
                    )
                  else if (featured != null) ...[
                    _HeroCampaignCard(campaign: featured),
                    const SizedBox(height: 14),
                    _TransparencyReportCard(campaign: featured),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AmanatDetailBody extends StatefulWidget {
  const _AmanatDetailBody({required this.campaignId});

  final int campaignId;

  @override
  State<_AmanatDetailBody> createState() => _AmanatDetailBodyState();
}

class _AmanatDetailBodyState extends State<_AmanatDetailBody> {
  bool _expanded = false;
  int _visibleDonorsCount = 5;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AmanatProvider>();
    final campaignId = widget.campaignId;
    Future.microtask(() {
      provider.refreshCampaign(campaignId);
      provider.startLiveUpdates(campaignId: campaignId);
    });
  }

  @override
  void dispose() {
    context.read<AmanatProvider>().stopLiveUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmanatProvider>();
    AmanatCampaign? campaign;
    for (final item in state.campaigns) {
      if (item.id == widget.campaignId) {
        campaign = item;
        break;
      }
    }
    if (campaign == null) {
      if (state.error != null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 9, 15, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AmanatHeader(title: _amanatHomeTitle),
              const SizedBox(height: 24),
              _AmanatErrorState(
                message: state.error!,
                onRetry: () => context.read<AmanatProvider>().refreshCampaign(
                  widget.campaignId,
                ),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    final selectedCampaign = campaign;
    final bottomSafe = math.max(MediaQuery.viewPaddingOf(context).bottom, 16.0);
    final totalDonors = selectedCampaign.donors.length;
    final shownCount = math.min(_visibleDonorsCount, totalDonors);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(15, 9, 15, 104 + bottomSafe),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AmanatHeader(title: _medreseDonationTitle),
              const SizedBox(height: 20),
              _DonationSummaryCard(campaign: selectedCampaign),
              const SizedBox(height: 14),
              _TransparencyReportCard(campaign: selectedCampaign),
              const SizedBox(height: 18),
              _CampaignDescriptionCard(
                campaign: selectedCampaign,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              const SizedBox(height: 22),
              const Text(
                'Последние пожертвования',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedCampaign.donors.isEmpty)
                const _AmanatEmptyState(
                  message:
                      'Пока никто не сделал пожертвование. Вы можете помочь первым',
                )
              else ...[
                for (int i = 0; i < shownCount; i++)
                  _DonorRow(
                    donation: selectedCampaign.donors[i],
                    showDivider: i != shownCount - 1,
                  ),
                if (totalDonors > _visibleDonorsCount) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: Color(0xFFFFD6B8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onPressed: () {
                          setState(() {
                            _visibleDonorsCount += 5;
                          });
                        },
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        label: Text(
                          'Показать ещё (${totalDonors - _visibleDonorsCount})',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        Positioned(
          left: 15,
          right: 15,
          bottom: 16 + bottomSafe,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _showDonateSheet(context, selectedCampaign),
              child: const Text('Пожертвовать на Медресе'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmanatHeader extends StatelessWidget {
  const _AmanatHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final compactTitle = title.length <= 18;
    return SizedBox(
      height: compactTitle ? 48 : 58,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Назад',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              splashRadius: 22,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 30,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              title,
              maxLines: compactTitle ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: compactTitle ? 24 : 20,
                height: 1.08,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCampaignCard extends StatelessWidget {
  const _HeroCampaignCard({required this.campaign});

  final AmanatCampaign campaign;

  void _openDetails(BuildContext context) {
    context.push('${AmanatDetailScreen.route}?id=${campaign.id}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetails(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 22,
              spreadRadius: -4,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CampaignImage(
                      imageUrl: campaign.coverImageUrl,
                      warm: true,
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.38)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _medreseDonationTitle,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Нужно: ${_money(campaign.neededAmount)} сом',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StackedProgressBar(
                      height: 14,
                      voluntary: campaign.voluntaryProgress,
                      safa: campaign.safaProgress,
                      remaining: campaign.remainingProgress,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Собрано: ${_money(campaign.collectedAmount)} сома',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            height: 16,
                            child: VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${campaign.helpersCount} человека помогли',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8425),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () =>
                                _showDonateSheet(context, campaign),
                            child: const Text('На Медресе'),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black.withValues(
                                alpha: .32,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: .72),
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _openDetails(context),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                            ),
                            iconAlignment: IconAlignment.end,
                            label: const Text('Подробнее'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignDescriptionCard extends StatelessWidget {
  const _CampaignDescriptionCard({
    required this.campaign,
    required this.expanded,
    required this.onToggle,
  });

  final AmanatCampaign campaign;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: SizedBox(
              height: 152,
              width: double.infinity,
              child: _CampaignImage(imageUrl: campaign.coverImageUrl),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Описание сбора',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.description,
            maxLines: expanded ? null : 3,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onToggle,
            child: Text(expanded ? 'Скрыть' : 'Читать полностью'),
          ),
          const SizedBox(height: 6),
          _InfoLine(label: 'Цель', value: campaign.goal),
          const SizedBox(height: 8),
          _InfoLine(label: 'Дата завершения', value: campaign.endsAt),
          const SizedBox(height: 8),
          _InfoLine(
            label: 'Необходимая сумма',
            value: '${_money(campaign.neededAmount)} сом',
          ),
        ],
      ),
    );
  }
}

class _TransparencyReportCard extends StatelessWidget {
  const _TransparencyReportCard({this.campaign});

  final AmanatCampaign? campaign;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _openTransparencyReports(context, campaign),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 22,
                spreadRadius: -4,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 27,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Прозрачность',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Все отчетные документы',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        height: 1.05,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8F8F94),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: const Color(0xFFFFF2E8),
                  minimumSize: const Size(86, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _openTransparencyReports(context, campaign),
                child: const Text('Посмотреть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openTransparencyReports(BuildContext context, AmanatCampaign? campaign) {
  if (campaign == null) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TransparencyDocumentsSheet(campaign: campaign),
  );
}

class _TransparencyDocumentsSheet extends StatelessWidget {
  const _TransparencyDocumentsSheet({required this.campaign});

  final AmanatCampaign campaign;

  Future<void> _openDocument(BuildContext context, AmanatDocument doc) async {
    if (doc.fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл документа недоступен')),
      );
      return;
    }
    final uri = Uri.tryParse(doc.fileUrl);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть документ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = math.max(MediaQuery.viewPaddingOf(context).bottom, 16.0);
    final docs = campaign.documents;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Отчётные документы',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          if (docs.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2E8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${docs.length}',
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        campaign.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8F8F94),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Flexible(
            child: docs.isEmpty
                ? Padding(
                    padding: EdgeInsets.fromLTRB(24, 36, 24, 36 + bottomSafe),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF2E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Документы готовятся к публикации',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Все чеки, накладные, сметы и акты выполненных работ будут публиковаться здесь по мере реализации проекта.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return _DocumentTile(
                        document: doc,
                        onTap: () => _openDocument(context, doc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.onTap});

  final AmanatDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.description_outlined;
    Color iconColor = const Color(0xFFF59E0B);
    Color bgColor = const Color(0xFFFEF3C7);

    if (document.isPdf) {
      iconData = Icons.picture_as_pdf_outlined;
      iconColor = const Color(0xFFE11D48);
      bgColor = const Color(0xFFFFE4E6);
    } else if (document.isImage) {
      iconData = Icons.image_outlined;
      iconColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFDBEAFE);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (document.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        document.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                    if (document.createdAt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        document.createdAt,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8F8F94),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmanatEmptyState extends StatelessWidget {
  const _AmanatEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8F8F94),
        ),
      ),
    );
  }
}

class _AmanatErrorState extends StatelessWidget {
  const _AmanatErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmanatLoadingBlock extends StatelessWidget {
  const _AmanatLoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _CampaignImage extends StatelessWidget {
  const _CampaignImage({this.imageUrl, this.warm = false});

  final String? imageUrl;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!.trim(),
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildFallback(),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Image.asset(
      AppImages.amanatBanner,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: warm
                ? const [
                    Color(0xFFE88A38),
                    Color(0xFFC75B16),
                    Color(0xFF8C3E0F),
                  ]
                : const [
                    Color(0xFF0D6EFD),
                    Color(0xFF0B5ED7),
                    Color(0xFF084298),
                  ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.volunteer_activism_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

Future<void> _showDonateSheet(
  BuildContext context,
  AmanatCampaign campaign,
) async {
  context.read<AmanatProvider>().clearError();
  final amountController = TextEditingController(text: '500');
  var isAnonymous = false;
  var paymentStarting = false;
  String? amountError;
  String? paymentError;
  const amounts = [100, 500, 1000, 5000];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomSafe = math.max(
            MediaQuery.viewPaddingOf(context).bottom,
            16.0,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + bottomSafe + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _medreseDonationTitle,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Цель сбора: ${campaign.goal.isEmpty ? _medreseDonationTitle : campaign.goal}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amounts.map((preset) {
                    final isSelected =
                        amountController.text == preset.toString();
                    return ChoiceChip(
                      label: Text('$preset сом'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFE8D6),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF374151),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      onSelected: (_) {
                        setSheetState(() {
                          amountController.text = preset.toString();
                          amountError = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Другая сумма (сом)',
                    errorText: amountError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (amountError != null) {
                      setSheetState(() => amountError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isAnonymous,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setSheetState(() => isAnonymous = val ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Пожертвовать анонимно',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (paymentError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    paymentError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: paymentStarting
                        ? null
                        : () async {
                            final raw = amountController.text.trim();
                            final parsed = int.tryParse(raw);
                            if (parsed == null || parsed <= 0) {
                              setSheetState(() {
                                amountError = 'Введите корректную сумму';
                              });
                              return;
                            }
                            setSheetState(() {
                              paymentStarting = true;
                              paymentError = null;
                            });
                            try {
                              final flow =
                                  context.read<FinikPaymentFlowProvider>();
                              flow.reset();
                              await flow.startAmanatDonationPayment(
                                campaignId: campaign.id,
                                amount: parsed,
                                isAnonymous: isAnonymous,
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              if (!context.mounted) return;
                              final router = GoRouter.of(context);
                              final paid = await router.pushNamed<bool>(
                                'finik_pay',
                              );
                              if (paid == true && context.mounted) {
                                final messenger = ScaffoldMessenger.of(context);
                                await context
                                    .read<AmanatProvider>()
                                    .refreshCampaign(campaign.id);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Спасибо за пожертвование на Медресе',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (sheetContext.mounted) {
                                setSheetState(() {
                                  paymentStarting = false;
                                  paymentError =
                                      'Не удалось начать оплату: $e';
                                });
                              }
                            }
                          },
                    child: paymentStarting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Перейти к оплате',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  amountController.dispose();
}

class _DonationSummaryCard extends StatelessWidget {
  const _DonationSummaryCard({required this.campaign});

  final AmanatCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Нужно: ${_money(campaign.neededAmount)} сом',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _StackedProgressBar(
            height: 14,
            voluntary: campaign.voluntaryProgress,
            safa: campaign.safaProgress,
            remaining: campaign.remainingProgress,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Собрано: ${_money(campaign.collectedAmount)} сома',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: Color(0xFFB7B7BE),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${campaign.helpersCount} человека помогли',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB7B7BE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LegendRow(
            color: const Color(0xFF3EBD44),
            label: 'Добровольные пожертвования',
            amount: '${_money(campaign.voluntaryAmount)} сом',
          ),
          const SizedBox(height: 7),
          _LegendRow(
            color: const Color(0xFF148CFF),
            label: 'Процентные сборы от Safa',
            amount: '${_money(campaign.safaAmount)} сом',
          ),
          const SizedBox(height: 7),
          _LegendRow(
            color: const Color(0xFFFF8425),
            label: 'Остаток',
            amount: '${_money(campaign.remainingAmount)} сом',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    this.amount,
  });

  final Color color;
  final String label;
  final String? amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          Text(
            amount!,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

class _DonorRow extends StatelessWidget {
  const _DonorRow({required this.donation, required this.showDivider});

  final AmanatDonation donation;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.group_outlined,
              size: 24,
              color: Color(0xFFB7B7BE),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                border: showDivider
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFFE7E7E7), width: 1),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.donorLabel,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Пожертвовано: ${_money(donation.amount)} сом',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8F8F94),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedProgressBar extends StatelessWidget {
  const _StackedProgressBar({
    required this.height,
    required this.voluntary,
    required this.safa,
    required this.remaining,
  });

  final double height;
  final double voluntary;
  final double safa;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final vFlex = (voluntary * 1000).round();
    final sFlex = (safa * 1000).round();
    final rFlex = math.max((remaining * 1000).round(), 0);
    final total = vFlex + sFlex + rFlex;

    if (total <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          color: const Color(0xFFE5E7EB),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (vFlex > 0)
              Expanded(
                flex: vFlex,
                child: Container(color: const Color(0xFF3EBD44)),
              ),
            if (sFlex > 0)
              Expanded(
                flex: sFlex,
                child: Container(color: const Color(0xFF148CFF)),
              ),
            if (rFlex > 0)
              Expanded(
                flex: rFlex,
                child: Container(color: const Color(0xFFFF8425)),
              ),
          ],
        ),
      ),
    );
  }
}

String _money(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final left = text.length - i;
    buffer.write(text[i]);
    if (left > 1 && left % 3 == 1) buffer.write(' ');
  }
  return buffer.toString();
}
