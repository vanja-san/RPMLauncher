import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';

class RPMLThemeData {
  final RPMLThemeType type;
  final Color mainColor;

  final Color backgroundColor;

  final Color textColor;
  final Color subTextColor;

  const RPMLThemeData({
    required this.type,
    required this.mainColor,
    required this.backgroundColor,
    required this.textColor,
    required this.subTextColor,
  });

  factory RPMLThemeData.byType(RPMLThemeType type) {
    switch (type) {
      case RPMLThemeType.light:
        return RPMLThemeData.light();
      case RPMLThemeType.dark:
        return RPMLThemeData.dark();
    }
  }

  factory RPMLThemeData.light() {
    return const RPMLThemeData(
      type: RPMLThemeType.light,
      mainColor: Colors.white,
      backgroundColor: Color(0xFFE5E5E5),
      textColor: Color(0xFF000000),
      subTextColor: Colors.black87,
    );
  }

  factory RPMLThemeData.dark() {
    return const RPMLThemeData(
      type: RPMLThemeType.dark,
      mainColor: Colors.black,
      backgroundColor: Color(0xFF1E1E1E),
      textColor: Color(0xFFFFFFFF),
      subTextColor: Colors.white70,
    );
  }
}