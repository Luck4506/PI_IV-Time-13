package br.com.puccampinas.trilhas;

// Informa ao Node.js se os campos foram aprovados e a mensagem correspondente.
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
