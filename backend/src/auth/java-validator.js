import { enviarPedidoTcp } from '../tcp-client.js';

export function createJavaValidator(port) {
  return async pedido => {
    const resultado = await enviarPedidoTcp(pedido, {
      host: '127.0.0.1',
      port,
      tempo: 3_000,
      limite: 8 * 1024,
    });

    if (typeof resultado?.valido !== 'boolean' || typeof resultado.mensagem !== 'string') {
      throw new Error('Resposta inválida do validador Java.');
    }

    return resultado;
  };
}
