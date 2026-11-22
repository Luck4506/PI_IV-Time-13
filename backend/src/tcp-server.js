// Autoria de Lucas Soares Gonçalves RA 25009467
import { createServer } from 'node:net';
import { rotaDeAutenticacao } from './auth/http.js';
import { criarLeitorDeLinha, LimiteDeMensagemError, limitePedido, limiteResposta } from './tcp-line.js';

const tempoConexao = 20_000;

export async function tratarPedidoTcp(linha, atender, ip) {
  let pedido;

  try {
    pedido = JSON.parse(linha);
  } catch {
    return { status: 400, corpo: { erro: 'JSON inválido.' } };
  }

  return atender(pedido, ip);
}

export function atenderConexao(socket, atender) {
  const lerLinha = criarLeitorDeLinha(limitePedido);
  const prazo = setTimeout(() => socket.destroy(), tempoConexao);

  socket.on('error', () => socket.destroy());
  socket.once('close', () => clearTimeout(prazo));

  function responder(resposta) {
    if (socket.destroyed || socket.writableEnded) return;

    let linha = JSON.stringify(resposta);
    if (Buffer.byteLength(linha) > limiteResposta) {
      linha = JSON.stringify({
        status: 503,
        corpo: { erro: 'Resposta muito grande. Reduza a consulta e tente novamente.' },
      });
    }

    socket.end(linha + '\n');
  }

  function pararLeitura() {
    socket.off('data', lerParte);
    socket.off('end', fecharPedidoIncompleto);
  }

  async function lerParte(parte) {
    let linha;
    try {
      linha = lerLinha(parte);
    } catch (erro) {
      pararLeitura();

      if (erro instanceof LimiteDeMensagemError) {
        return responder({ status: 413, corpo: { erro: 'Pedido muito grande.' } });
      }
      return responder({ status: 400, corpo: { erro: 'Use texto em UTF-8.' } });
    }

    if (linha === null) return;

    // Uma conexão atende um pedido. Paramos de ler enquanto a rota trabalha.
    pararLeitura();
    try {
      responder(await tratarPedidoTcp(linha, atender, socket.remoteAddress));
    } catch {
      responder({ status: 503, corpo: { erro: 'Serviço indisponível. Tente novamente.' } });
    }
  }

  function fecharPedidoIncompleto() {
    pararLeitura();
    responder({
      status: 400,
      corpo: { erro: 'Pedido incompleto. Termine a mensagem com uma quebra de linha.' },
    });
  }

  socket.on('data', lerParte);
  socket.once('end', fecharPedidoIncompleto);
}

export function criarServidorTcp(atender) {
  const atenderTcp = (pedido, ip) => {
    if (pedido?.metodo === 'POST' && typeof pedido.caminho === 'string' && rotaDeAutenticacao(pedido.caminho)) {
      return { status: 404, corpo: { erro: 'Use o servidor Java para entrar ou se cadastrar.' } };
    }

    return atender(pedido, ip);
  };

  // O cliente pode encerrar somente o envio e continuar lendo. Mantemos a
  // outra metade da conexão aberta até terminar de escrever a resposta.
  return createServer({ allowHalfOpen: true }, socket => atenderConexao(socket, atenderTcp));
}
