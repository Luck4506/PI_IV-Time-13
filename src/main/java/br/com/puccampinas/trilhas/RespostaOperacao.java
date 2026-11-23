// Autoria de Henrique RA 25005651

package br.com.puccampinas.trilhas;
import com.google.gson.JsonObject;

public class RespostaOperacao extends Comunicado {
    private final boolean sucesso;  // operacao concluida ou nao.
    private final String codigo;    // identifica o resultado, como CADASTRO_REALIZADO.
    private final String mensagem;  // mensagem apresentada ao usuario.
    private final JsonObject dados; // dados retornados pelo Node.js; pode ser nulo.

    public RespostaOperacao(boolean sucesso, String codigo, String mensagem, JsonObject dados)
    throws Exception {
        if (codigo == null || codigo.isBlank()) throw new Exception("Codigo invalido.");

        if (mensagem == null || mensagem.isBlank()) throw new Exception("Mensagem invalida.");

        this.sucesso = sucesso;
        this.codigo = codigo;
        this.mensagem = mensagem;
        this.dados = dados;
    }

    public boolean isSucesso() {
        return this.sucesso;
    }

    public String getCodigo() {
        return this.codigo;
    }

    public String getMensagem() {
        return this.mensagem;
    }

    public JsonObject getDados() {
        return this.dados;
    }

}
