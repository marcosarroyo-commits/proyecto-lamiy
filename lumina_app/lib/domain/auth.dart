class Auth {
  static String? validarUsuario(String usuario) {
    final valor = usuario.trim();
    if (valor.isEmpty) {
      return 'Ingresa tu usuario o documento';
    }
    if (valor.contains(RegExp(r'\s'))) {
      return 'El usuario no puede tener espacios';
    }
    return null;
  }

  static String? validarContrasena(String contrasena) {
    if (contrasena.isEmpty) {
      return 'Ingresa tu clave';
    }
    return null;
  }

  static String? validarOtp(String codigo) {
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      return 'Ingresa los 6 dígitos del código';
    }
    return null;
  }

  /// 1104259632 → 11******32
  static String enmascararUsuario(String usuario) {
    final u = usuario.trim();
    if (u.length < 5) return u;
    return '${u.substring(0, 2)}${'*' * (u.length - 4)}${u.substring(u.length - 2)}';
  }
}
