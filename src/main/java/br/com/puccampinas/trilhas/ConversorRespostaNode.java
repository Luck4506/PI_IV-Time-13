// Autoria de Henrique RA 25005651

package br.com.puccampinas.trilhas;
import java.net.http.HttpResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

// Converte status e corpo HTTP para a resposta que o Java devolve pelo TCP.
public class ConversorRespostaNode {

    public RespostaOperacao converterCadastro(HttpResponse<String> resposta) throws Exception {
        if(resposta == null) throw new Exception("Resposta invalida.");

        int status = resposta.statusCode();

        if(status >= 500 && status <= 599) {
            // Erros do servidor podem trazer texto ou HTML, sem um objeto JSON válido.
            return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                        "Servico indisponivel. Tente novamente.", null);
        }

        String body = resposta.body();

        if(body == null || body.isBlank()) {
            throw new Exception("Resposta do Node.js sem conteudo.");
        }

        JsonElement elemento = JsonParser.parseString(body);

        if(!elemento.isJsonObject()) {
            throw new Exception("Resposta do Node.js deve ser um objeto JSON.");
        }

        JsonObject json = elemento.getAsJsonObject();

        if(status == 201) {
            if(!json.has("token") || !json.get("token").isJsonPrimitive()
                || !json.get("token").getAsJsonPrimitive().isString()
                || json.get("token").getAsString().isBlank())
            {
                throw new Exception("Resposta de cadastro sem token valido.");
            }

            if(!json.has("usuario") || !json.get("usuario").isJsonObject()) {
                throw new Exception("Resposta de cadastro sem usuario valido.");
            }

            return new RespostaOperacao(
                    true, "CADASTRO_REALIZADO", "Cadastro realizado.", json
            );
        }

        if(status == 409) {
            // Recusa de cadastro: exige uma mensagem textual no campo erro.
            if(json.get("erro") == null || json.get("erro").isJsonNull()) {
                throw new Exception("Resposta de erro do Node.js invalida.");
            }

            if(!json.get("erro").isJsonPrimitive() || !json.get("erro").getAsJsonPrimitive().isString()) {
                throw new Exception("Resposta de erro do Node.js invalida.");
            }

            String mensagem = json.get("erro").getAsString();

            if(mensagem.isBlank()) {
                throw new Exception("Resposta de erro do Node.js invalida.");
            }

            return new RespostaOperacao(false, "OPERACAO_RECUSADA", mensagem, null);
        }

        // Outros status ainda não têm tratamento específico; o serviço os traduz em indisponibilidade.
        throw new Exception("Status de cadastro inesperado: " + status);
    }

    public String converterParaJson(RespostaOperacao operacao) throws Exception {
        if(operacao == null) throw new Exception("Operacao invalida.");

        // Mantém campos nulos no texto JSON, como "dados": null nas recusas.
        Gson gson = new GsonBuilder().serializeNulls().create();
        return gson.toJson(operacao);
    }

    public RespostaOperacao converterLogin(HttpResponse<String> resposta) throws Exception {
        if(resposta == null) throw new Exception("Resposta invalida.");

        int status = resposta.statusCode();

        if(status >= 500 && status <= 599) {
            return new RespostaOperacao(
                    false, "SERVICO_INDISPONIVEL",
                    "Servico indisponivel. Tente novamente.", null
            );
        }

        String body = resposta.body();

        if(body == null || body.isBlank()) {
            throw new Exception("Resposta do Node.js sem conteudo.");
        }

        // Interpreta o texto HTTP; o resultado deve ser um objeto JSON.
        JsonElement elemento = JsonParser.parseString(body);

        if(!elemento.isJsonObject()) {
            throw new Exception("Resposta do Node.js deve ser um objeto JSON.");
        }

        JsonObject json = elemento.getAsJsonObject();

        if(status == 200) {
            // Login concluido deve trazer o token textual e objeto com os dados do usuario.
            if(!json.has("token") || !json.get("token").isJsonPrimitive()
                || !json.get("token").getAsJsonPrimitive().isString()
                || json.get("token").getAsString().isBlank())
            {
                throw new Exception("Resposta de login sem token valido.");
            }

            if(!json.has("usuario") || !json.get("usuario").isJsonObject()) {
                throw new Exception("Resposta de login sem usuario valido.");
            }

            return new RespostaOperacao(true, "LOGIN_REALIZADO", "Login realizado.", json);
        }

        if(status == 401) {
            // Credenciais recusadas: preserva a mensagem publica devolvida pelo Node.
            if(!json.has("erro") || !json.get("erro").isJsonPrimitive()
                || !json.get("erro").getAsJsonPrimitive().isString())
            {
                throw new Exception("Resposta de erro do Node.js invalida.");
            }

            String mensagem = json.get("erro").getAsString();

            if(mensagem.isBlank()) {
                throw new Exception("Resposta de erro do Node.js invalida.");
            }

            return new RespostaOperacao(false, "OPERACAO_RECUSADA", mensagem, null);
        }

        throw new Exception("Status de login inesperado: " + status);
    }
}
