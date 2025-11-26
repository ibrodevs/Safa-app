import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/model/delivery_point_model.dart';
import '../../provider/delivery_autocomplete_provider.dart';

class IntermediatePointSheet extends StatefulWidget {
  const IntermediatePointSheet({
    required this.addressLine,
    required this.placeLine,
    super.key,
  });

  final String addressLine;
  final String placeLine;

  @override
  State<IntermediatePointSheet> createState() => _IntermediatePointSheetState();
}

class _IntermediatePointSheetState extends State<IntermediatePointSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Промежуточная точка',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.addressLine,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.placeLine,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: _greyText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _tileBorder, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Откуда отправка',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC7CFD9),
                                    ),
                                  ),
                                  cursorColor: Colors.black,
                                  textInputAction: TextInputAction.next,
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
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 20,
                                color: _accent,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Карта',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (autocomplete.loading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],

                  if (!autocomplete.loading &&
                      autocomplete.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: autocomplete.items.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: _tileBorder,
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
                                color: _greyText,
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

                  const SizedBox(height: 22),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: _tileBorder,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(
                        child: _TagButton(
                          title: 'Контейнер',
                          iconAsset: 'assets/icons/ic_box.svg',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _TagButton(
                          title: 'Проход',
                          iconAsset: 'assets/icons/ic_box.svg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Далее'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagButton extends StatelessWidget {
  const _TagButton({
    required this.title,
    required this.iconAsset,
  });

  final String title;
  final String iconAsset;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
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
              fontWeight: FontWeight.w700,
              color: _greyText,
            ),
          ),
        ],
      ),
    );
  }
}