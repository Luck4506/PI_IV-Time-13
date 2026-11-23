// Autoria de Lucas Soares Gonçalves RA 25009467
export const limitePedido = 64 * 1024;
export const limiteResposta = 8 * 1024 * 1024;

export class LimiteDeMensagemError extends Error {}

export function criarLeitorDeLinha(limite) {
  const partes = [];
  let tamanho = 0;

  return parte => {
    // Procuramos o fim da linha nos bytes. Uma letra acentuada pode vir
    // dividida em duas partes, por isso o UTF-8 só é lido no final.
    const fim = parte.indexOf(10);
    const trecho = fim < 0 ? parte : parte.subarray(0, fim);
    tamanho += trecho.length;

    if (tamanho > limite) throw new LimiteDeMensagemError();

    partes.push(trecho);
    if (fim < 0) return null;

    const bytes = Buffer.concat(partes, tamanho);
    return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  };
}
