




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
