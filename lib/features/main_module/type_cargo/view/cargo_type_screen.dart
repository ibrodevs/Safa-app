import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../map/data/model/delivery_point_model.dart';
import '../data/model/cargo_segment_model.dart';
import '../data/repo/cargo_segments_repo.dart';
import '../provider/cargo_segments_provider.dart';
class CargoRouteArgs {
  final List<DeliveryPoint> stops;
  const CargoRouteArgs({required this.stops});
}
class CargoTypeScreen extends StatelessWidget {
  const CargoTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      CargoSegmentsProvider(CargoSegmentsRepository())..refresh(),
      child: const _CargoTypeBody(),
    );
  }
}

class _CargoTypeBody extends StatefulWidget {
  const _CargoTypeBody();

  @override
  State<_CargoTypeBody> createState() => _CargoTypeBodyState();
}

class _CargoTypeBodyState extends State<_CargoTypeBody> {
  static const _accent = Color(0xFFE67E22);
  static const _grey = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  int? _selectedIndex;
  int _qty = 5;

  String _selectedName(List<CargoSegment> segments) {
    final i = _selectedIndex;
    if (i == null || i < 0 || i >= segments.length) return '';
    return segments[i].name;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CargoSegmentsProvider>();
    final segments = provider.items;
    final extra = GoRouterState.of(context).extra;
    final routeArgs = extra is CargoRouteArgs ? extra : null;
    final stops = routeArgs?.stops ?? const <DeliveryPoint>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () =>
                    context.canPop() ? context.pop() : null,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Color(0xFFB9C0C8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Тип груза',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (stops.isNotEmpty) ...[
                for (int i = 0; i < stops.length; i++) ...[
                  _PlaceLine(
                    title: stops[i].title,
                    subtitle: stops[i].subtitle,
                  ),
                  if (i != stops.length - 1) ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 28,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
                const SizedBox(height: 18),
              ] else ...[
                const _PlaceLine(
                  title: 'Маршрут не выбран',
                  subtitle: 'Вернитесь и выберите точки на карте',
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 18),

              if (provider.loading && segments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (provider.error != null && segments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.red,
                    ),
                  ),
                )
              else if (segments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'Типы груза не найдены',
                      style: TextStyle(
                        fontSize: 15,
                        color: _grey,
                      ),
                    ),
                  )
                else ...[
                    for (var i = 0; i < segments.length; i += 2) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _tile(
                              index: i,
                              segment: segments[i],
                            ),
                          ),
                          const SizedBox(width: 18),
                          if (i + 1 < segments.length)
                            Expanded(
                              child: _tile(
                                index: i + 1,
                                segment: segments[i + 1],
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                      if (i + 2 < segments.length) const SizedBox(height: 18),
                    ],
                  ],

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _selectedIndex == null || segments.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                  key: const ValueKey('qty-block'),
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выберите количество:',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите количество ${_selectedName(segments).toLowerCase()}ов',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: _grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: _tileBorder,
                                  width: 1,
                                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_box.svg',
                                    width: 36,
                                    height: 36,
                                    colorFilter:
                                    const ColorFilter.mode(
                                      _accent,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '$_qty',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      height: 1.0,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      _selectedName(segments),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.0,
                                        fontWeight:
                                        FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _roundBtn(
                            icon: Icons.remove,
                            onTap: () => setState(() {
                              _qty = (_qty - 1).clamp(0, 999);
                            }),
                          ),
                          const SizedBox(width: 12),
                          _roundBtn(
                            icon: Icons.add,
                            onTap: () => setState(() {
                              _qty = (_qty + 1).clamp(0, 999);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedIndex == null
                              ? null
                              : () {
                            final seg = segments[_selectedIndex!];
                            context.pop(
                              CargoTypeResult(
                                segmentId: seg.id,
                                quantity: _qty,
                              ),
                            );
                          },
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(_accent),
                            foregroundColor: WidgetStatePropertyAll(Colors.white),
                            elevation: WidgetStatePropertyAll(0),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                          child: const Text('Далее'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required int index,
    required CargoSegment segment,
  }) {
    final selected = _selectedIndex == index;

    return _CargoTile(
      iconAsset: 'assets/icons/ic_box.svg',
      title: segment.name,
      subtitle: segment.description,
      selected: selected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 64,
      width: 64,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _tileBorder, width: 1),
            ),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hasSub = subtitle.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        if (hasSub) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9FA4AD),
            ),
          ),
        ],
      ],
    );
  }
}

class _CargoTile extends StatelessWidget {
  const _CargoTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  static const _accent = Color(0xFFE67E22);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _tileBorder, width: 1),
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
            child: Stack(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        iconAsset,
                        width: 36,
                        height: 36,
                        colorFilter: const ColorFilter.mode(
                          _accent,
                          BlendMode.srcIn,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9FA4AD),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: selected
                      ? Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  )
                      : Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFF1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class CargoTypeResult {
  final int segmentId;
  final int quantity;

  const CargoTypeResult({
    required this.segmentId,
    required this.quantity,
  });
}
