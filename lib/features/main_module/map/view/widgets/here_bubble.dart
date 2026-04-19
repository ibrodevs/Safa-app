import 'package:dogo/features/main_module/map/view/widgets/parsed_adress.dart';
import 'package:flutter/material.dart';

class HereBubble extends StatelessWidget {
  const HereBubble({
    super.key,
    this.onEdit,
    this.address,
    this.loading = false,
    this.marketTitle,
    this.detail,
    this.error,
  });

  final VoidCallback? onEdit;
  final String? address;
  final bool loading;
  final String? marketTitle;
  final String? detail;
  final String? error;
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    String titleLine;
    String subtitleLine;

    if (loading) {
      titleLine = marketTitle ?? 'Определяем адрес...';
      subtitleLine = 'Определяем адрес...';
    } else if (address == null || address!.isEmpty) {
      titleLine = marketTitle ?? 'Определяем адрес...';
      subtitleLine = 'Определяем адрес...';
    } else {
      if (marketTitle != null || detail != null) {
        titleLine = marketTitle ?? 'Определяем адрес...';
        subtitleLine = detail ?? address!;
      } else {
        final parsed = parseAddressForUi(address);
        titleLine = parsed.marketTitle ?? 'Определяем адрес...';
        subtitleLine = parsed.detail ?? parsed.fullAfterCity;
      }
    }
    if (error != null && error!.isNotEmpty) {
      titleLine = 'Не удалось получить адрес';
      subtitleLine = 'Проверь интернет / доступ к геокодингу';
    } else if (loading) {}
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 188,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _tileBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Вы здесь',
              style: TextStyle(
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titleLine,
              style: const TextStyle(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitleLine,
              style: const TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: _greyText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
