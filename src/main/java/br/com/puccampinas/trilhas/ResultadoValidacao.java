package br.com.puccampinas.trilhas;

// Representa somente a validação dos campos; não confirma cadastro nem autenticação.
public class ResultadoValidacao extends Comunicado {
    private boolean valido;
    private String mensagem;

    public ResultadoValidacao(boolean valido, String mensagem) throws Exception {
        // A resposta deve conter uma mensagem tanto no sucesso quanto na falha.
        if(mensagem == null) {
            throw new Exception("Mensagem invalida.");
        }

        this.valido = valido;
        this.mensagem = mensagem;
    }

    public boolean isValido() {
        return this.valido;
    }

    public String getMensagem() {
        return this.mensagem;
    }
}
