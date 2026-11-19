package br.com.puccampinas.trilhas;
import java.net.http.HttpResponse;
import java.io.IOException;

// Encaminha o login validado e traduz falhas de comunicação para a resposta da operação.
public class ServicoLogin {
    private final ClienteNode clienteNode;

    public ServicoLogin(ClienteNode clienteNode) throws Exception {
        if(clienteNode == null) throw new Exception("ClienteNode invalido.");

        this.clienteNode = clienteNode;
    }

    public RespostaOperacao entrar(String loginJson) throws Exception {
        if(loginJson == null) throw new Exception("Login invalido.");

        try {
            HttpResponse<String> resposta = clienteNode.entrar(loginJson);
            try {
                return new ConversorRespostaNode().converterLogin(resposta);
            }
            catch(Exception erro) {
                // Resposta inesperada do Node vira indisponibilidade, sem confirmar o login.
                return new RespostaOperacao(false, "SERVICO_INDISPONIVEL",
                                            "Servico indisponivel. Tente novamente.", null);
            }
        }
        catch(IOException erro) {
            // Falhas de conexão e timeout recebem uma resposta pública de indisponibilidade.
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
