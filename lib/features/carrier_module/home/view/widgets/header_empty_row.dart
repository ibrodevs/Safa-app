import 'package:flutter/material.dart';

class HeaderEmptyRow extends StatelessWidget {
  const HeaderEmptyRow({super.key, required this.title, this.avatarUrl});

  final String title;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 14),
        _Avatar(avatarUrl: avatarUrl),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: 44, height: 44, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        'assets/images/img_placeholder.png',
        width: 44,
        height: 44,
        fit: BoxFit.cover,
      ),
    );
  }
}
