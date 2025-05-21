import 'package:flutter/material.dart';
import 'package:calma_flutter/core/constants/app_colors.dart';
import 'package:calma_flutter/core/constants/app_text_styles.dart';

/// AppTheme - Configuração de tema do aplicativo C'Alma
///
/// Centraliza a definição de tema utilizada em todo o aplicativo,
/// garantindo consistência visual e aderência ao design system.
class AppTheme {
  /// Retorna o tema claro do aplicativo
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.calmaBlue,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.calmaBlueLight,
        onPrimaryContainer: AppColors.calmaBlueDark,
        secondary: AppColors.calmaBlueDark,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.gray700,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray700,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.calmaBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.calmaBlue,
          side: const BorderSide(color: AppColors.calmaBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.calmaBlue,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gray700,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          textStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.calmaBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodySmall,
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Retorna o tema escuro do aplicativo
  static ThemeData get darkTheme {
    // Na versão inicial, utilizaremos apenas o tema claro
    // Implementação futura para o tema escuro
    return lightTheme;
  }

  // Não permitir instanciação
  const AppTheme._();
}
