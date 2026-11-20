import 'package:flutter/material.dart';
import 'package:lumina_app/services/local/secure_storage_service.dart';

abstract final class PreferenciaTema {
  static final ValueNotifier<ThemeMode> modo = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static final SecureStorageService _almacen = SecureStorageService();

  static bool get esOscuro => modo.value == ThemeMode.dark;

  static Future<void> cargar() async {
    final oscuro = await _almacen.leerTemaOscuro();
    modo.value = oscuro ? ThemeMode.dark : ThemeMode.light;
  }

  static void cambiar(bool oscuro) {
    modo.value = oscuro ? ThemeMode.dark : ThemeMode.light;
    _almacen.guardarTemaOscuro(oscuro);
  }

  static void alternar() => cambiar(!esOscuro);
}
