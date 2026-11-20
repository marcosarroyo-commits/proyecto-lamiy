import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina_app/theme/colores_app.dart';


class AppColors {
  static const Color primario = Color(0xFF8E4E6A);
  static const Color primarioOscuro = Color(0xFF5E2F45);
  static const Color malva = Color(0xFFB87B93);
  static const Color rubor = Color(0xFFF4E6EB);
  static const Color dorado = Color(0xFFC09A5B);
  static const Color doradoSuave = Color(0xFFF5ECDD);
  static const Color verde = Color(0xFF4F8A64);
  static const Color ambar = Color(0xFFC08A2C);
  static const Color rojoAlerta = Color(0xFFB4424F);
  static const Color textoTitulo = Color(0xFF2B2024);
}




class AppTheme {
  
  static TextStyle cormorant({
    double size = 14,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textoTitulo,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: size * 1.18,
      fontWeight: weight.value < 600 ? FontWeight.w600 : weight,
      color: color,
      height: 1.15,
    );
  }

  static TextStyle manrope({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textoTitulo,
  }) {
    return GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
  }

  static ThemeData get light => _tema(ColoresApp.claro, Brightness.light);

  static ThemeData get dark => _tema(ColoresApp.oscuro, Brightness.dark);

  static ThemeData _tema(ColoresApp c, Brightness brillo) {
    final base = ThemeData(useMaterial3: true, brightness: brillo);
    return base.copyWith(
      scaffoldBackgroundColor: c.fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primario,
        brightness: brillo,
      ).copyWith(
        primary: c.primario,
        surface: c.superficie,
        onSurface: c.textoTitulo,
        outline: c.borde,
      ),
      
      
      
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.manrope().fontFamily,
        bodyColor: c.textoTitulo,
        displayColor: c.textoTitulo,
      ),
      dividerColor: c.borde,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primario),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.superficie,
        headerBackgroundColor: AppColors.primario,
        headerForegroundColor: Colors.white,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.fondo,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      extensions: [c],
    );
  }

  static const List<BoxShadow> sombraSuave = [
    BoxShadow(color: Color(0x0F5E2F45), offset: Offset(0, 2), blurRadius: 6),
  ];
}
