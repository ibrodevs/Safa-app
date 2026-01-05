import 'dart:ui';

import 'package:dogo/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  static const titleBlackStyle = TextStyle(
    fontFamily: 'SFProDisplay',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.5,
    height: 1.1,
    color: Colors.black,
  );

  static const titleGreyStyle = TextStyle(
    fontFamily: 'SFProDisplay',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.subtitleGrey,
  );

  static const cardTitleStyle = TextStyle(
    fontFamily: 'SFProDisplay',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 0.2,
    color: Colors.black,
  );
  static const cardSubtitleStyle = TextStyle(
    fontFamily: 'SFProDisplay',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1,
    color: AppColors.greyText,
  );

  static const subtitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.2,
    letterSpacing: -0.6,
    color: AppColors.subtitleGrey,
  );
}
