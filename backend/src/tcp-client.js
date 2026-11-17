import { createConnection } from 'node:net';
import { criarLeitorDeLinha, LimiteDeMensagemError, limiteResposta } from './tcp-line.js';

export function enderecoApiTcp(config = process.env) {
  let host = config.TCP_HOST ?? '127.0.0.1';
  const port = Number(config.TCP_PORT ?? 3002);

  // Endereços de escuta em todas as interfaces não são destinos do cliente.
  if (host === '0.0.0.0') host = '127.0.0.1';
  if (host === '::') host = '::1';

  return { host, port };
}

export function consultarApiTcp(metodo, caminho, dados, token) {
  const destino = enderecoApiTcp();
  return enviarPedidoTcp({ metodo, caminho, dados, token }, { ...destino, tempo: 22_000 });
}

export function enviarPedidoTcp(pedido, { host, port, tempo = 5_000, limite = limiteResposta }) {
  return new Promise((resolve, reject) => {
    const mensagem = JSON.stringify(pedido) + '\n';
    const socket = createConnection({ host, port });
    const lerLinha = criarLeitorDeLinha(limite);
    let finalizado = false;

    const prazo = setTimeout(() => {
      socket.destroy(new Error('Tempo de espera pela resposta TCP excedido.'));
    }, tempo);

    socket.once('connect', () => socket.end(mensagem));
    socket.once('error', reject);
    socket.once('close', comErro => {
      clearTimeout(prazo);
      if (!finalizado && !comErro) {
        reject(new Error('A conexão TCP fechou antes da resposta.'));
      }
    });

    socket.on('data', parte => {
      try {
        const linha = lerLinha(parte);
        if (linha === null) return;

        resolve(JSON.parse(linha));
      } catch (erro) {
        const falha = erro instanceof LimiteDeMensagemError
          ? new Error('Resposta TCP muito grande.')
          : erro;
        reject(falha);
      }

      finalizado = true;
      socket.destroy();
    });
  });
}
