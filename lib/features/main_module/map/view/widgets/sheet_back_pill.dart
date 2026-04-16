import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SheetBackPill extends StatelessWidget {
  const SheetBackPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:  [
              SvgPicture.asset('assets/icons/ic_arrow.svg'),
              SizedBox(width: 6),
              Text(
                'Назад',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB9BEC7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
