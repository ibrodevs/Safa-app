import 'package:flutter/material.dart';

class PasswordEye extends StatelessWidget {
  const PasswordEye({
    super.key,
    required this.obscured,
    required this.onTap,
  });

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E9EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 14, // меньше
          color: const Color(0xFF8F97A3),
        ),
      ),
    );
  }
}
