import 'dart:ui';

import 'package:dogo/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles{
  static const TextStyle titleBlackStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.1,
    color: Colors.black,
  );

  static const  titleGreyStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.1,
    color: AppColors.subtitleGrey,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
    color: Colors.black,
  );
  static const  cardSubtitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.25,
    color: AppColors.greyText,
  );

  static const  TextStyle subtitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.25,
    color: AppColors.subtitleGrey,
  );
}


