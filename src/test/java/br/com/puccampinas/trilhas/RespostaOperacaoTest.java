package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

public class RespostaOperacaoTest {

    @Test
    void operacaoConcluida() throws Exception {
        JsonObject json = new JsonObject();
        json.addProperty("fruta", "Abacate");
        RespostaOperacao operacao = new RespostaOperacao(true,
                                                        "CADASTRO_REALIZADO",
                                                        "Cadastro realizado.",
                                                        json
        );
        assertTrue(operacao.isSucesso());
        assertEquals("CADASTRO_REALIZADO", operacao.getCodigo());
        assertEquals("Cadastro realizado.", operacao.getMensagem());
        assertEquals(json, operacao.getDados());
    }

    @Test
    void operacaoRecusada() throws Exception {
        JsonObject json = null;
        RespostaOperacao operacao = new RespostaOperacao(false,
                                                        "OPERACAO_RECUSADA",
                                                        "Email duplicado.",
                                                        json
        );
        assertFalse(operacao.isSucesso());
        assertEquals("OPERACAO_RECUSADA", operacao.getCodigo());
        assertEquals("Email duplicado.", operacao.getMensagem());
        assertNull(operacao.getDados());
    }

    @Test
    void serializarRecusaComDadosNulos() throws Exception {
        RespostaOperacao respostaRecusada = new RespostaOperacao(false, "OPERACAO_RECUSADA",
                                                                 "Email duplicado.", null);

        // Produz o texto JSON que o Java enviará ao Flutter pelo socket.
        String respostaEmJson = new ConversorRespostaNode().converterParaJson(respostaRecusada);
        // O teste interpreta esse texto para conferir o conteúdo que o Flutter receberá.
        JsonObject json = JsonParser.parseString(respostaEmJson).getAsJsonObject();

        // get() devolve JsonElement; getAs... extrai o valor Java para comparação.
        assertFalse(json.get("sucesso").getAsBoolean());
        assertEquals("OPERACAO_RECUSADA", json.get("codigo").getAsString());
        assertEquals("Email duplicado.", json.get("mensagem").getAsString());
        // Verifica que dados foi incluído como JSON null, em vez de ser omitido.
        assertTrue(json.has("dados"));
        assertTrue(json.get("dados").isJsonNull());
    }
}
