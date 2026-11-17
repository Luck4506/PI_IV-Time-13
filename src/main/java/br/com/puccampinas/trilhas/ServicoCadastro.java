package br.com.puccampinas.trilhas;
import java.net.http.HttpResponse;
import java.io.IOException;

public class ServicoCadastro {
    private final ClienteNode clienteNode;

    public ServicoCadastro(ClienteNode clienteNode) throws Exception {
        if(clienteNode == null) throw new Exception("ClienteNode invalido.");

        this.clienteNode = clienteNode;
    }

    public RespostaOperacao cadastrar(String cadastroJson) throws Exception {
        if(cadastroJson == null) throw new Exception("Cadastro invalido.");

        try {
            HttpResponse<String> resposta = clienteNode.cadastrar(cadastroJson);
            try {
                return new ConversorRespostaNode().converterCadastro(resposta);
            }
            catch(Exception erro) {
                return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                            "Servico indisponivel. Tente novamente.", null);
            }
        }
        catch(IOException erro) {
            return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                        "Servico indisponivel. Tente novamente.", null);
        }
        catch(InterruptedException erro) {
            Thread.currentThread().interrupt();
            throw erro;
        }
    }
}
