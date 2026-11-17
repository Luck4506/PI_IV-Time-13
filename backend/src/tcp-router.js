const metodos = ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'];

function objetoJson(valor) {
  return valor !== null && typeof valor === 'object' && !Array.isArray(valor);
}

function pedidoValido(pedido) {
  if (!objetoJson(pedido)) return false;

  const { metodo, caminho, token, dados } = pedido;
  const caminhoValido = typeof caminho === 'string' && /^\/(?:api|health)\//.test(caminho);
  const tokenValido = token === undefined || typeof token === 'string';
  const dadosValidos = dados === undefined || objetoJson(dados);

  return caminhoValido && metodos.includes(metodo) && tokenValido && dadosValidos;
}

function lerQuery(texto) {
  const query = Object.create(null);

  // Parâmetros repetidos ficam em lista para que a rota possa validar o valor.
  for (const [chave, valor] of new URLSearchParams(texto)) {
    if (chave in query) {
      query[chave] = [].concat(query[chave], valor);
    } else {
      query[chave] = valor;
    }
  }

  return query;
}

function encontrarRota(rotas, metodo, caminho) {
  const partes = caminho.split('/');

  for (const rota of rotas) {
    if (rota.metodo !== metodo || rota.partes.length !== partes.length) continue;

    const corresponde = rota.partes.every((parte, indice) => {
      return parte.startsWith(':') ? Boolean(partes[indice]) : parte === partes[indice];
    });
    if (!corresponde) continue;

    const params = Object.create(null);
    for (const [indice, parte] of rota.partes.entries()) {
      if (parte.startsWith(':')) {
        params[parte.slice(1)] = decodeURIComponent(partes[indice]);
      }
    }

    return { rota, params };
  }

  return null;
}

// Cada rota recebe o pedido já lido pelo socket e monta o objeto de resposta.
export function criarRotas(tratarErro, antesDeAtender = () => {}) {
  const rotas = [];

  function registrar(metodo) {
    return (caminho, ...etapas) => {
      rotas.push({ metodo, partes: caminho.split('/'), etapas: etapas.flat() });
    };
  }

  async function atender(pedido, ip) {
    if (!pedidoValido(pedido)) {
      return { status: 400, corpo: { erro: 'Pedido TCP inválido.' } };
    }

    const { metodo, caminho, token, dados } = pedido;
    const [caminhoSemQuery] = caminho.split('?', 1);
    const path = caminhoSemQuery.replace(/\/$/, '');
    const query = lerQuery(caminho.slice(caminhoSemQuery.length + 1));

    let encontrada;
    try {
      encontrada = encontrarRota(rotas, metodo, path);
    } catch (erro) {
      if (erro instanceof URIError) {
        return { status: 400, corpo: { erro: 'Caminho inválido.' } };
      }
      return tratarErro(erro, path);
    }

    try {
      antesDeAtender(path);

      if (!encontrada) {
        return { status: 404, corpo: { erro: 'Rota não encontrada.' } };
      }

      const { rota, params } = encontrada;
      const req = { path, params, query, token, ip, body: dados };
      let resposta;
      let codigo = 200;

      const res = {
        status(novoCodigo) {
          codigo = novoCodigo;
          return res;
        },
        json(corpo) {
          resposta = { status: codigo, corpo };
        },
        end() {
          res.json({});
        },
      };

      // Cada etapa chama next() somente depois de passar pela sua validação.
      let indice = 0;
      const next = () => rota.etapas[indice++]?.(req, res, next);
      await next();

      return resposta ?? { status: 503, corpo: { erro: 'O pedido ficou sem resposta.' } };
    } catch (erro) {
      return tratarErro(erro, path);
    }
  }

  return {
    get: registrar('GET'),
    post: registrar('POST'),
    patch: registrar('PATCH'),
    put: registrar('PUT'),
    delete: registrar('DELETE'),
    atender,
  };
}

export function limitarTentativas(mensagem) {
  const tentativas = new Map();
  const intervalo = 15 * 60 * 1000;
  let proximaLimpeza = 0;

  return (req, res, next) => {
    const agora = Date.now();

    if (agora >= proximaLimpeza) {
      for (const [ip, dados] of tentativas) {
        if (dados.expiraEm <= agora) tentativas.delete(ip);
      }
      proximaLimpeza = agora + intervalo;
    }

    // O IP é lido do socket e é o mesmo em pedidos de rotas diferentes.
    let dados = tentativas.get(req.ip);
    if (!dados || dados.expiraEm <= agora) {
      dados = { total: 0, expiraEm: agora + intervalo };
      tentativas.set(req.ip, dados);
    }

    dados.total++;
    if (dados.total > 30) {
      return res.status(429).json({ erro: mensagem });
    }

    return next();
  };
}
