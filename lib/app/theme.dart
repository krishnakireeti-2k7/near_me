import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    // ✅ Updated primary and secondary colors to match the chat UI.
    primary: Color(0xFF42A5F5), // A vibrant, light blue for a fresh look
    onPrimary: Colors.white,
    secondary: Color(0xFF64B5F6), // A slightly lighter blue
    onSecondary: Colors.white,
    surface: Color(0xFFF5F5F5), // Light gray background
    background: Color(0xFFFFFFFF), // White
    onSurface: Color(0xFF1C1B1F), // Dark gray text
    error: Color(0xFFB00020),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16),
    bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14),
    titleLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5),
    elevation: 0,
  ),
);
