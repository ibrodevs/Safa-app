
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.prefixText,
    this.maxLenth,
  });
  final TextEditingController? controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? prefixText;
  final int? maxLenth;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontFamily: 'SFProText',
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: Color(0xFFD0D5DD),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: suffix,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 15,
          fontFamily: 'SFProText',
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: Colors.black,
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: Colors.black,
      ),
    );
  }
}