// Autoria de Lucas Soares Gonçalves RA 25009467
import 'tcp_client.dart';

class JavaAuthClient {
  const JavaAuthClient(this._tcp);

  static const loginPath = '/api/auth/login';
  static const registrationPath = '/api/auth/cadastro';

  final TcpClient _tcp;

  Future<TcpResponse> send(TcpRequest request) async {
    final isLogin = request.path == loginPath;
    final data = request.data!;
    final payload = isLogin
        ? {
            'tipo': 'VALIDAR_LOGIN',
            'email': data['email'],
            'senha': data['senha'],
          }
        : _registrationPayload(data);

    try {
      return _readResponse(await _tcp.sendJson(payload), isLogin);
    } on TcpRequestTooLarge {
      return const TcpResponse({'erro': 'Pedido muito grande.'}, 413);
    }
  }

  Map<String, dynamic> _registrationPayload(Map<String, dynamic> data) {
    final profile = switch (data['perfil']) {
      'student' => 1,
      'teacher' => 2,
      _ => throw const FormatException('Perfil inválido.'),
    };
    final isStudent = profile == 1;
    final educational = !isStudent || data['cadastroEducacional'] == true;

    // O Java espera os campos na raiz e códigos numéricos para perfil e ano.
    // Código de professor é texto, pois pode começar com zero.
    return {
      'tipo': 'VALIDAR_CADASTRO',
      'nome': data['nome'],
      'email': data['email'],
      'senha': data['senha'],
      'dataNascimento': data['dataNascimento'],
      'perfil': profile,
      if (isStudent) 'anoEscolar': _schoolYear(data['anoEscolar']),
      if (!isStudent && data['codProfessor'] != null)
        'codProfessor': data['codProfessor'],
      'cadastroEducacional': educational,
      if (educational && data['codigoEscola'] != null)
        'codigoEscola': data['codigoEscola'],
      if (isStudent && educational && data['codigoTurma'] != null)
        'codigoTurma': data['codigoTurma'],
      'termosAceitos': data['termosAceitos'],
    };
  }

  int _schoolYear(Object? year) => switch (year) {
    'Outro' => 0,
    '1º ano' || '1º ano do Ensino Médio' => 1,
    '2º ano' || '2º ano do Ensino Médio' => 2,
    '3º ano' || '3º ano do Ensino Médio' => 3,
    _ => throw const FormatException('Ano escolar inválido.'),
  };

  TcpResponse _readResponse(Map<String, dynamic> data, bool isLogin) {
    final success = data['sucesso'];
    final code = data['codigo'];
    final message = data['mensagem'];
    final body = data['dados'];

    if (success is! bool ||
        code is! String ||
        message is! String ||
        message.trim().isEmpty) {
      throw const FormatException('Resposta Java inválida.');
    }

    if (success) {
      final expectedCode = isLogin ? 'LOGIN_REALIZADO' : 'CADASTRO_REALIZADO';
      if (code != expectedCode || body is! Map<String, dynamic>) {
        throw const FormatException('Resposta Java inválida.');
      }
      return TcpResponse(body, isLogin ? 200 : 201);
    }

    if (body != null) throw const FormatException('Resposta Java inválida.');

    // Nas recusas, o Java repassa só o texto de erro do Node. Os códigos
    // abaixo recuperam o estado da confirmação, que continua sem sessão.
    if (code == 'OPERACAO_RECUSADA') {
      if (isLogin && message.startsWith('[EMAIL_NAO_CONFIRMADO] ')) {
        return TcpResponse({
          'codigo': 'EMAIL_NAO_CONFIRMADO',
          'erro': message.substring('[EMAIL_NAO_CONFIRMADO] '.length),
        }, 403);
      }
      final emailSent = message.startsWith('[EMAIL_CONFIRMACAO_ENVIADA] ');
      final emailFailed = message.startsWith('[EMAIL_CONFIRMACAO_PENDENTE] ');
      final emailSending = message.startsWith('[EMAIL_CONFIRMACAO_EM_ENVIO] ');
      if (!isLogin && (emailSent || emailFailed || emailSending)) {
        return TcpResponse({
          'verificacaoPendente': true,
          'emailEnviado': emailSending ? null : emailSent,
        }, 201);
      }
    }

    final status = switch (code) {
      'VALIDACAO_INVALIDA' => 400,
      'OPERACAO_RECUSADA' => isLogin ? 401 : 409,
      'SERVICO_INDISPONIVEL' => 503,
      _ => throw const FormatException('Código de resposta Java desconhecido.'),
    };
    return TcpResponse({'erro': message, 'codigo': code}, status);
  }
}
