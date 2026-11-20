/// Recuperación de contraseña en modo demostración.
///
/// La API Ehily no expone este servicio. La hoja de requerimientos pide
/// solo el formulario, el código OTP y el mensaje de solicitud enviada.
/// Código de prueba: 123456.
class RecuperacionService {
  static const codigoDemo = '123456';

  Future<void> solicitarCodigo(String usuario) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<bool> verificarCodigo(String usuario, String codigo) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return codigo == codigoDemo;
  }
}
