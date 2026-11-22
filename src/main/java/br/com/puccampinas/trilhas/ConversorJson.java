// Sofia de Sousa e Henrique Young

package br.com.puccampinas.trilhas;
import com.google.gson.Gson;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import com.google.gson.JsonElement;
import com.google.gson.JsonSyntaxException;

public class ConversorJson {

    public String converterResultado(ResultadoValidacao resultado) {
        Gson gson = new Gson();
        // Converte o objeto Java em uma String contendo JSON.
        return gson.toJson(resultado);
    }

    // Centraliza a leitura de texto: ausência vira null; outros tipos são rejeitados.
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

    public Comunicado converterPedido(String texto) throws Exception {
        // Interpreta o texto recebido para permitir a consulta dos campos.
        JsonElement elemento;
        try {
            elemento = JsonParser.parseString(texto);
        } catch (JsonSyntaxException erro) {
            throw new Exception("JSON invalido.");
        }

        if(!elemento.isJsonObject()) {
            throw new Exception("O pedido deve ser um objeto JSON.");
        }

        JsonObject json = elemento.getAsJsonObject();

        // O tipo identifica a operação e também precisa ser texto.
        String tipo = lerTexto(json, "tipo");

        if(tipo == null) throw new Exception("Tipo de pedido invalido.");

        // Cada tipo chama seu método; qualquer outro é rejeitado.
        if(tipo.equals("VALIDAR_CADASTRO")) {
            return lerCadastro(json);
        }
        else if(tipo.equals("VALIDAR_LOGIN")) {
            return lerLogin(json);
        }
        else {
            throw new Exception("Tipo de pedido nao suportado. Esperado: VALIDAR_CADASTRO ou VALIDAR_LOGIN.");
        }
    }

    // Lê e-mail e senha; a validação fica no construtor do PedidoDeLogin.
    private PedidoDeLogin lerLogin(JsonObject json) throws Exception {
        final String email = lerTexto(json, "email");
        final String senha = lerTexto(json, "senha");

        return new PedidoDeLogin(email, senha);
    }

    // Lê os campos do cadastro; o construtor do PedidoDeCadastro valida.
    private PedidoDeCadastro lerCadastro(JsonObject json) throws Exception {
        // Campos ausentes permanecem nulos para a validação do pedido.
        // final impede reatribuição dos textos lidos; não altera sua validação.
        final String nome = lerTexto(json, "nome");
        final String senha = lerTexto(json, "senha");
        final String email = lerTexto(json, "email");
        final String codProfessor = lerTexto(json, "codProfessor");
        final String perfilTexto = lerTexto(json, "perfil");
        final String nascimentoTexto = lerTexto(json, "dataNascimento");
        // Os valores convertidos serão preenchidos conforme os dados recebidos.
        Perfil perfil = null;
        LocalDate dataNascimento = null;
        Integer anoEscolar = null;

        // Traduz os valores usados pelo Node.js para o enum Java.
        if(perfilTexto != null) {
            if(perfilTexto.equals("student")) {
                perfil = Perfil.ESTUDANTE;
            }
            else if(perfilTexto.equals("teacher")) {
                perfil = Perfil.PROFESSOR;
            }
        }

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

        // Converte a data no formato AAAA-MM-DD e trata datas impossíveis.
        if(nascimentoTexto != null) {
            try{
                dataNascimento = LocalDate.parse(nascimentoTexto);
            } catch (DateTimeParseException erro) {
                throw new Exception("Informe uma data de nascimento valida, entre 01/01/1800 e hoje.");
            }
        }

        // O construtor executa validar(); dados inválidos impedem o retorno.
        return new PedidoDeCadastro(nome, dataNascimento, senha, email, perfil, anoEscolar, codProfessor);
    }
}