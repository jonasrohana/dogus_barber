import 'package:flutter/material.dart';

ColorTheme getThemeById(int? id) {
  switch(id) {
    case 0: return mainThemeDark;
    default: return mainThemeDark;
  }
}

class ColorTheme {
  int id;
  bool isDarkTheme;
  Color backgroundColor;
  Color buttonColor;
  Color primary;
  Color secondary;
  Color textColor;
  Color primaryText;
  Color secondaryText;

  ColorTheme({
    required this.id,
    required this.isDarkTheme,
    required this.backgroundColor,
    required this.buttonColor,
    required this.primary,
    required this.secondary,
    required this.textColor,
    required this.primaryText,
    required this.secondaryText
  });
}

List<ColorTheme> allThemes = [
  mainThemeDark,
];

ColorTheme mainThemeDark = ColorTheme(
  id: 0,
  isDarkTheme: true,
  backgroundColor: const Color(0xff101010),
  buttonColor: const Color(0xff1D1D1D),
  primary: const Color(0xff0A986A),
  secondary: const Color(0xff353535),
  textColor: Colors.white,
  primaryText: Colors.white,
  secondaryText: Colors.white
);
