import 'package:dogo/features/main_module/map/provider/delivery_autocomplete_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/model/delivery_point_model.dart';
import '../../provider/delivery_address_provider.dart';
import 'map_picker_screen.dart';

class DeliveryPointSheet extends StatelessWidget {
  const DeliveryPointSheet({
    super.key,
    required this.mainTitle,
    this.bazarTitle,
  });

  final String mainTitle;
  final String? bazarTitle;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: const Color(0x33000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
              child: _DeliveryPointContent(
                mainTitle: mainTitle,
                bazarTitle: bazarTitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryPointContent extends StatefulWidget {
  const _DeliveryPointContent({
    required this.mainTitle,
    required this.bazarTitle,
  });

  final String mainTitle;
  final String? bazarTitle;

  @override
  State<_DeliveryPointContent> createState() => _DeliveryPointContentState();
}

class _DeliveryPointContentState extends State<_DeliveryPointContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryAutocompleteProvider>().clearSuggestions();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autocomplete = context.watch<DeliveryAutocompleteProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Точка доставки',
            style: TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.mainTitle,
            style: const TextStyle(
              fontSize: 18,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.bazarTitle ?? 'Алкан базары',
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: DeliveryPointSheet._greyText,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DeliveryPointSheet._tileBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_box.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          DeliveryPointSheet._accent,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: false,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Откуда отправка',
                            hintStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: DeliveryPointSheet._greyText,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          cursorColor: Colors.black,
                          onChanged: context
                              .read<DeliveryAutocompleteProvider>()
                              .onQueryChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  context.read<DeliveryAutocompleteProvider>().clearSuggestions();

                  final p = await Navigator.of(context).push<DeliveryPoint>(
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(value: context.read<DeliveryAddressProvider>()),
                          ChangeNotifierProvider.value(value: context.read<DeliveryAutocompleteProvider>()),
                        ],
                        child: const MapPickerScreen(
                          initial: LatLng(42.8746, 74.6122),
                          title: 'Точка доставки',
                        ),
                      ),
                    ),
                  );

                  if (p != null && context.mounted) {
                    Navigator.of(context).pop(p);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: DeliveryPointSheet._accent,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(
                  Icons.near_me_rounded,
                  size: 20,
                ),
                label: const Text('Карта'),
              ),
            ],
          ),

          if (autocomplete.loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],

          if (!autocomplete.loading && autocomplete.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: autocomplete.items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: DeliveryPointSheet._tileBorder,
                ),
                itemBuilder: (context, index) {
                  final item = autocomplete.items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      item.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DeliveryPointSheet._greyText,
                      ),
                    ),
                    onTap: () {
                      final point = DeliveryPoint(
                        title: item.title,
                        subtitle: item.address,
                        lat: item.lat,
                        lon: item.lon,
                      );
                      Navigator.of(context).pop(point);
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1, color: DeliveryPointSheet._tileBorder),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: DeliveryTypeChip(title: 'Контейнер'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DeliveryTypeChip(title: 'Проход'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryPointSheet._accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryTypeChip extends StatelessWidget {
  const DeliveryTypeChip({required this.title, super.key});

  final String title;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              _accent,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _greyText,
            ),
          ),
        ],
      ),
    );
  }
}
