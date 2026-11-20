import 'package:flutter/material.dart';

/// Paleta de Lumina Beauty Center para modo claro y oscuro.
///
/// Se accede desde cualquier widget con `context.colores`.
@immutable
class ColoresApp extends ThemeExtension<ColoresApp> {
  const ColoresApp({
    required this.fondo,
    required this.superficie,
    required this.primario,
    required this.primarioOscuro,
    required this.acento,
    required this.acentoFondo,
    required this.textoTitulo,
    required this.textoSecundario,
    required this.textoEtiqueta,
    required this.textoOscuro,
    required this.textoGris,
    required this.textoSutil,
    required this.hint,
    required this.borde,
    required this.bordeTarjeta,
    required this.badgeFondo,
    required this.verde,
    required this.verdeOscuro,
  });

  /// Fondo general (crema en claro).
  final Color fondo;

  /// Tarjetas, barras y campos.
  final Color superficie;

  /// Ciruela Lumina: acciones e íconos.
  final Color primario;

  /// Títulos y textos destacados.
  final Color primarioOscuro;

  /// Dorado del logo: detalles de marca.
  final Color acento;
  final Color acentoFondo;

  final Color textoTitulo;
  final Color textoSecundario;
  final Color textoEtiqueta;
  final Color textoOscuro;
  final Color textoGris;
  final Color textoSutil;
  final Color hint;
  final Color borde;
  final Color bordeTarjeta;

  /// Rubor: fondos de íconos, chips y pestaña activa.
  final Color badgeFondo;
  final Color verde;
  final Color verdeOscuro;

  static const ColoresApp claro = ColoresApp(
    fondo: Color(0xFFFBF7F4),
    superficie: Color(0xFFFFFFFF),
    primario: Color(0xFF8E4E6A),
    primarioOscuro: Color(0xFF5E2F45),
    acento: Color(0xFFC09A5B),
    acentoFondo: Color(0xFFF5ECDD),
    textoTitulo: Color(0xFF2B2024),
    textoSecundario: Color(0xFF7A6A70),
    textoEtiqueta: Color(0xFF4A3B41),
    textoOscuro: Color(0xFF2B2024),
    textoGris: Color(0xFF5C4C52),
    textoSutil: Color(0xFF8C7C82),
    hint: Color(0xFFB3A6AB),
    borde: Color(0xFFE3D6D1),
    bordeTarjeta: Color(0xFFEFE6E2),
    badgeFondo: Color(0xFFF4E6EB),
    verde: Color(0xFF4F8A64),
    verdeOscuro: Color(0xFF2F6B45),
  );

  static const ColoresApp oscuro = ColoresApp(
    fondo: Color(0xFF161114),
    superficie: Color(0xFF221A1E),
    primario: Color(0xFFE3A9C0),
    primarioOscuro: Color(0xFFF0C6D6),
    acento: Color(0xFFD9B77A),
    acentoFondo: Color(0xFF3A2F22),
    textoTitulo: Color(0xFFF4EDEF),
    textoSecundario: Color(0xFFBFAFB5),
    textoEtiqueta: Color(0xFFDCCDD3),
    textoOscuro: Color(0xFFF4EDEF),
    textoGris: Color(0xFFD2C4CA),
    textoSutil: Color(0xFFA8979E),
    hint: Color(0xFF7D6E74),
    borde: Color(0xFF43363C),
    bordeTarjeta: Color(0xFF2E2428),
    badgeFondo: Color(0xFF3A2530),
    verde: Color(0xFF7BC596),
    verdeOscuro: Color(0xFF7BC596),
  );

  @override
  ColoresApp copyWith({
    Color? fondo, Color? superficie, Color? primario, Color? primarioOscuro,
    Color? acento, Color? acentoFondo, Color? textoTitulo,
    Color? textoSecundario, Color? textoEtiqueta, Color? textoOscuro,
    Color? textoGris, Color? textoSutil, Color? hint, Color? borde,
    Color? bordeTarjeta, Color? badgeFondo, Color? verde, Color? verdeOscuro,
  }) => ColoresApp(
    fondo: fondo ?? this.fondo,
    superficie: superficie ?? this.superficie,
    primario: primario ?? this.primario,
    primarioOscuro: primarioOscuro ?? this.primarioOscuro,
    acento: acento ?? this.acento,
    acentoFondo: acentoFondo ?? this.acentoFondo,
    textoTitulo: textoTitulo ?? this.textoTitulo,
    textoSecundario: textoSecundario ?? this.textoSecundario,
    textoEtiqueta: textoEtiqueta ?? this.textoEtiqueta,
    textoOscuro: textoOscuro ?? this.textoOscuro,
    textoGris: textoGris ?? this.textoGris,
    textoSutil: textoSutil ?? this.textoSutil,
    hint: hint ?? this.hint,
    borde: borde ?? this.borde,
    bordeTarjeta: bordeTarjeta ?? this.bordeTarjeta,
    badgeFondo: badgeFondo ?? this.badgeFondo,
    verde: verde ?? this.verde,
    verdeOscuro: verdeOscuro ?? this.verdeOscuro,
  );

  @override
  ColoresApp lerp(ThemeExtension<ColoresApp>? other, double t) {
    if (other is! ColoresApp) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresApp(
      fondo: m(fondo, other.fondo),
      superficie: m(superficie, other.superficie),
      primario: m(primario, other.primario),
      primarioOscuro: m(primarioOscuro, other.primarioOscuro),
      acento: m(acento, other.acento),
      acentoFondo: m(acentoFondo, other.acentoFondo),
      textoTitulo: m(textoTitulo, other.textoTitulo),
      textoSecundario: m(textoSecundario, other.textoSecundario),
      textoEtiqueta: m(textoEtiqueta, other.textoEtiqueta),
      textoOscuro: m(textoOscuro, other.textoOscuro),
      textoGris: m(textoGris, other.textoGris),
      textoSutil: m(textoSutil, other.textoSutil),
      hint: m(hint, other.hint),
      borde: m(borde, other.borde),
      bordeTarjeta: m(bordeTarjeta, other.bordeTarjeta),
      badgeFondo: m(badgeFondo, other.badgeFondo),
      verde: m(verde, other.verde),
      verdeOscuro: m(verdeOscuro, other.verdeOscuro),
    );
  }
}

extension ColoresContexto on BuildContext {
  ColoresApp get colores {
    final tema = Theme.of(this);
    return tema.extension<ColoresApp>() ??
        (tema.brightness == Brightness.dark
            ? ColoresApp.oscuro
            : ColoresApp.claro);
  }
}
