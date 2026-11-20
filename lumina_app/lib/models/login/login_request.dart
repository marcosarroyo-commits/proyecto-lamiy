class LoginRequest {
  const LoginRequest({required this.usuario, required this.clave});

  final String usuario;
  final String clave;

  Map<String, dynamic> toJson() => {'usuario': usuario, 'clave': clave};
}
