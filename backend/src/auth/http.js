// Autoria de Lucas Soares Gonçalves RA 25009467
import { createServer } from 'node:http';
import { limitePedido } from '../tcp-line.js';

const cadastro = '/api/auth/cadastro';
const login = '/api/auth/login';

export function rotaDeAutenticacao(caminho) {
  const rota = caminho.split('?', 1)[0].replace(/\/$/, '');
  return rota === cadastro || rota === login;
}

function respostaParaJava(caminho, { status, corpo }) {
  if (caminho === cadastro && status === 201 && corpo.verificacaoPendente) {
    const codigo = corpo.emailEnviado === null ? 'EMAIL_CONFIRMACAO_EM_ENVIO'
      : corpo.emailEnviado ? 'EMAIL_CONFIRMACAO_ENVIADA' : 'EMAIL_CONFIRMACAO_PENDENTE';
    return { status: 409, corpo: { erro: `[${codigo}] Confirme seu e-mail para continuar.` } };
  }

  // O Java devolve só a mensagem nas recusas. O código permite ao app abrir
  // a confirmação sem o Node emitir uma sessão para a conta pendente.
  if (caminho === login && status === 403 && corpo.codigo === 'EMAIL_NAO_CONFIRMADO') {
    return { status: 401, corpo: { erro: `[${corpo.codigo}] ${corpo.erro}` } };
  }

  if (status >= 400 && status < 500) {
    return { status: caminho === cadastro ? 409 : 401, corpo: { erro: corpo.erro } };
  }

  return { status, corpo };
}

function responder(res, status, corpo) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(corpo));
}

export function criarServidorAuthHttp(atender) {
  return createServer(async (req, res) => {
    const caminho = req.url;
    if (caminho !== cadastro && caminho !== login) {
      return responder(res, 404, { erro: 'Rota não encontrada.' });
    }
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST');
      return responder(res, 405, { erro: 'Método não aceito.' });
    }
    if (!/^application\/json(?:\s*;|$)/i.test(req.headers['content-type'] ?? '')) {
      return responder(res, 415, { erro: 'Envie um pedido JSON.' });
    }

    let dados;
    try {
      const partes = [];
      let tamanho = 0;
      for await (const parte of req.iterator({ destroyOnReturn: false })) {
        tamanho += parte.length;
        if (tamanho > limitePedido) {
          res.setHeader('Connection', 'close');
          return responder(res, 413, { erro: 'Pedido muito grande.' });
        }
        partes.push(parte);
      }
      dados = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(partes)));
    } catch {
      return responder(res, 400, { erro: 'Pedido JSON inválido.' });
    }

    const resultado = await atender({ metodo: 'POST', caminho, dados }, req.socket.remoteAddress);
    const { status, corpo } = respostaParaJava(caminho, resultado);
    responder(res, status, corpo);
  });
}
