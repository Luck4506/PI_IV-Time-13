package br.com.puccampinas.trilhas;
import com.google.gson.Gson;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import com.google.gson.JsonElement;
import com.google.gson.JsonSyntaxException;

// Lê cadastro e login do protocolo TCP; os pedidos validam as regras dos campos.
public class ConversorJson {

    // Mantém a conversão do resultado de validação; a resposta final usa RespostaOperacao.
    public String converterResultado(ResultadoValidacao resultado) {
        Gson gson = new Gson();
        // Converte o objeto Java em uma String contendo JSON.
        return gson.toJson(resultado);
    }

    // Ausência e JSON null viram null; números e booleanos não são convertidos em texto.
    private String lerTexto(JsonObject json, String nomeDoCampo) throws Exception {
        if(json.get(nomeDoCampo) == null || json.get(nomeDoCampo).isJsonNull()) {
            return null;
        }
        // O || evita consultar isString() em objetos ou listas.
        else if(!json.get(nomeDoCampo).isJsonPrimitive() ||
                !json.get(nomeDoCampo).getAsJsonPrimitive().isString()) {
            throw new Exception("Campo " + nomeDoCampo + " deve ser informado como texto.");
        }
        else {
            return json.get(nomeDoCampo).getAsString();
        }
    }

    // Somente ausência permite valor padrão; JSON null e tipos não booleanos são rejeitados.
    private Boolean lerBooleano(JsonObject json, String nomeDoCampo) throws Exception {
        if(json.get(nomeDoCampo) == null) return null;

        if(json.get(nomeDoCampo).isJsonNull()) {
            throw new Exception("Campo " + nomeDoCampo + " deve ser informado como booleano.");
        }

        if(!json.get(nomeDoCampo).isJsonPrimitive() || !json.get(nomeDoCampo).getAsJsonPrimitive().isBoolean()) {
            throw new Exception("Campo " + nomeDoCampo + " deve ser informado como booleano.");
        }

        return json.get(nomeDoCampo).getAsBoolean();
    }

    public Comunicado converterPedido(String texto) throws Exception {
        // Interpreta o texto; erros de sintaxe recebem uma mensagem própria.
        JsonElement elemento;
        try {
            elemento = JsonParser.parseString(texto);
        } catch (JsonSyntaxException erro) {
            throw new Exception("JSON invalido.");
        }

        // JSON válido também pode ser lista ou valor simples; o pedido deve ser objeto.
        if(!elemento.isJsonObject()) {
            throw new Exception("O pedido deve ser um objeto JSON.");
        }

        JsonObject json = elemento.getAsJsonObject();

        // O tipo identifica a operação e também precisa ser texto.
        String tipo = lerTexto(json, "tipo");

        if(tipo == null) throw new Exception("Tipo de pedido invalido.");

        // Cada operação usa seu próprio método de leitura.
        if(tipo.equals("VALIDAR_CADASTRO")) {
            return lerCadastro(json);
        } else if (tipo.equals("VALIDAR_LOGIN")) {
            return lerLogin(json);
        } else {
            throw new Exception("Tipo de pedido nao suportado. Esperado: VALIDAR_CADASTRO ou VALIDAR_LOGIN.");
        }
    }

    // Serializa um pedido já validado e normalizado, sem o tipo exclusivo do protocolo TCP.
    // Este formato ainda depende do alinhamento com o endpoint do Node real.
    public String converterCadastroParaNode(PedidoDeCadastro pedido) {
        JsonObject json = new JsonObject();

        json.addProperty("nome", pedido.getNome());
        json.addProperty("email", pedido.getEmail());
        json.addProperty("senha", pedido.getSenha());
        json.addProperty("dataNascimento", pedido.getDataNascimento().toString());
        json.addProperty("cadastroEducacional", pedido.isCadastroEducacional());
        json.addProperty("termosAceitos", pedido.isTermosAceitos());

        if(pedido.getPerfil() == Perfil.ESTUDANTE) {
            json.addProperty("perfil", 1);
            json.addProperty("anoEscolar", pedido.getAnoEscolar());
        }
        else {
            json.addProperty("perfil", 2);
            json.addProperty("codProfessor", pedido.getCodProfessor());
        }

        if(pedido.getCodigoEscola() != null) {
            json.addProperty("codigoEscola", pedido.getCodigoEscola());
        }

        if(pedido.getCodigoTurma() != null) {
            json.addProperty("codigoTurma", pedido.getCodigoTurma());
        }

        return json.toString();
    }

    private PedidoDeCadastro lerCadastro(JsonObject json) throws Exception {
        // Lê textos e booleanos uma vez; obrigatoriedade e padrões são tratados no pedido.
        final String nome = lerTexto(json, "nome");
        final String senha = lerTexto(json, "senha");
        final String email = lerTexto(json, "email");
        final String codProfessor = lerTexto(json, "codProfessor");
        final String nascimentoTexto = lerTexto(json, "dataNascimento");
        final Boolean cadastroEducacional = lerBooleano(json, "cadastroEducacional");
        final Boolean termosAceitos = lerBooleano(json, "termosAceitos");
        final String codigoEscola = lerTexto(json, "codigoEscola");
        final String codigoTurma = lerTexto(json, "codigoTurma");
        final Perfil perfil;

        // Começam ausentes e podem ser preenchidos após conversão; por isso não são final.
        Integer perfilNumero = null;
        LocalDate dataNascimento = null;
        Integer anoEscolar = null;

        // Exige número inteiro no JSON, evitando converter textos ou truncar 1.5 para 1.
        if(json.get("anoEscolar") != null && !json.get("anoEscolar").isJsonNull()) {
            if(json.get("anoEscolar").isJsonPrimitive() &&
                    json.get("anoEscolar").getAsJsonPrimitive().isNumber())
            {
                try {
                    anoEscolar = json.get("anoEscolar").getAsBigDecimal().intValueExact();
                } catch (ArithmeticException erro) {
                    throw new Exception("Ano escolar deve ser um numero inteiro.");
                }
            }
            else {
                throw new Exception("Ano escolar deve ser um numero inteiro.");
            }
        }

        // O perfil recebido deve ser número inteiro, nunca texto como "1" ou "student".
        if(json.get("perfil") != null && !json.get("perfil").isJsonNull()) {
            if(json.get("perfil").isJsonPrimitive() &&
                    json.get("perfil").getAsJsonPrimitive().isNumber())
            {
                try {
                    perfilNumero = json.get("perfil").getAsBigDecimal().intValueExact();
                } catch (ArithmeticException erro) {
                    throw new Exception("Perfil deve ser um numero inteiro.");
                }
            }
            else {
                throw new Exception("Perfil deve ser um numero inteiro.");
            }
        }

        // Traduz 1/2 para o enum usado internamente; cada caminho atribui perfil uma vez.
        if(perfilNumero != null) {
            if (perfilNumero < 1 || perfilNumero > 2) {
                throw new Exception("Perfil precisa ter o valor 1 ou 2.");
            }

            if (perfilNumero == 1) {
                perfil = Perfil.ESTUDANTE;
            } else {
                perfil = Perfil.PROFESSOR;
            }
        }
        else {
            throw new Exception("Perfil invalido.");
        }

        // Converte AAAA-MM-DD; o pedido verifica depois os limites de 1800 a 3000.
        if(nascimentoTexto != null) {
            try{
                dataNascimento = LocalDate.parse(nascimentoTexto);
            } catch (DateTimeParseException erro) {
                throw new Exception("Informe uma data de nascimento valida, entre 01/01/1800 e 01/01/3000.");
            }
        }

        // O construtor executa validar(); dados inválidos impedem o retorno.
        return new PedidoDeCadastro(nome, dataNascimento, senha, email, perfil, anoEscolar, codProfessor,
                cadastroEducacional, codigoEscola, termosAceitos, codigoTurma);
    }

    // Lê os campos do login; o construtor verifica e-mail e senha não vazia.
    private PedidoDeLogin lerLogin(JsonObject json) throws Exception {
        final String email = lerTexto(json, "email");
        final String senha = lerTexto(json, "senha");

        return new PedidoDeLogin(email, senha);
    }
}
