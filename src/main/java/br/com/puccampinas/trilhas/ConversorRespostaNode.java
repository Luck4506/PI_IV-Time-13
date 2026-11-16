package br.com.puccampinas.trilhas;
import java.net.http.HttpResponse;
import com.google.gson.JsonParser;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class ConversorRespostaNode {

    public RespostaOperacao converterCadastro(HttpResponse<String> resposta) throws Exception {
        if(resposta == null) throw new Exception("Resposta invalida.");

        int status = resposta.statusCode();

        if(status >= 500 && status <= 599) {
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
            return new RespostaOperacao(true, "CADASTRO_REALIZADO", "Cadastro realizado.", json);
        }

        if(status == 409) {
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

        throw new Exception("Status de cadastro inesperado: " + status);
    }

    public String converterParaJson(RespostaOperacao operacao) throws Exception {
        if(operacao == null) throw new Exception("Operacao invalida.");

        // Mantém campos nulos no texto JSON, como "dados": null nas recusas.
        Gson gson = new GsonBuilder().serializeNulls().create();
        return gson.toJson(operacao);
    }
}
