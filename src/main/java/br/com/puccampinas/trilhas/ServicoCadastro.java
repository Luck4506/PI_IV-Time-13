// Autoria de Henrique RA 25005651 e Arthur Valerio De Santi RA 25006924

package br.com.puccampinas.trilhas;
import java.io.IOException;
import java.net.http.HttpResponse;

// Encaminha o cadastro já validado e traduz falhas de comunicação para a resposta da operação.
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
                // Resposta inesperada do Node não representa cadastro concluído nem erro nos campos.
                return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                            "Servico indisponivel. Tente novamente.", null);
            }
        }
        catch(IOException erro) {
            // Inclui falhas de conexão e timeout; não repete automaticamente o cadastro.
            return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                        "Servico indisponivel. Tente novamente.", null);
        }
        catch(InterruptedException erro) {
            // A supervisora decide encerrar; o serviço mantém a interrupção e a propaga.
            Thread.currentThread().interrupt();
            throw erro;
        }
    }
}
