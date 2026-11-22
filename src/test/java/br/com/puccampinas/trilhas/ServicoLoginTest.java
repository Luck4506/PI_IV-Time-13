package br.com.puccampinas.trilhas;
import java.net.URI;
import java.net.http.HttpResponse;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

// Verifica falhas do serviço de login sem depender do Node real ou dos bancos.
public class ServicoLoginTest {

    private static final String LOGIN_JSON =
            "{\"email\":\"ana@example.com\",\"senha\":\"Abcde12!\"}";

    // Simula falha de comunicação sem abrir uma conexão real.
    private static class ClienteNodeIndisponivel extends ClienteNode {

        public ClienteNodeIndisponivel() throws Exception {
            super(URI.create("http://127.0.0.1"));
        }

        @Override
        public HttpResponse<String> entrar(String loginJson) throws Exception {
            throw new IOException("Falha simulada.");
        }
    }

    // Permite conferir a interrupção sem depender de tempo de rede ou de outra thread.
    private static class ClienteNodeInterrompido extends ClienteNode {

        public ClienteNodeInterrompido() throws Exception {
            super(URI.create("http://127.0.0.1"));
        }

        @Override
        public HttpResponse<String> entrar(String loginJson) throws Exception {
            throw new InterruptedException("Interrupcao simulada.");
        }
    }

    // Executa o cliente HTTP real contra uma resposta controlada pelo próprio teste.
    private RespostaOperacao executarLoginComResposta(int status, String corpo) throws Exception {
        HttpServer servidor = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);

        try {
            servidor.createContext("/api/auth/login", troca -> {
                try {
                    byte[] bytes = corpo.getBytes(StandardCharsets.UTF_8);
                    // Consome o pedido e devolve o status e o conteúdo definidos pelo cenário.
                    troca.getRequestBody().readAllBytes();
                    troca.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    troca.sendResponseHeaders(status, bytes.length);
                    troca.getResponseBody().write(bytes);
                } finally {
                    troca.close();
                }
            });

            servidor.start();
            URI endereco = URI.create("http://127.0.0.1:" + servidor.getAddress().getPort());
            ServicoLogin servico = new ServicoLogin(new ClienteNode(endereco));
            return servico.entrar(LOGIN_JSON);
        } finally {
            // Cada cenário libera sua porta mesmo se o serviço lançar uma exceção.
            servidor.stop(0);
        }
    }

    // Indisponibilidade não deve devolver sucesso, detalhes internos ou dados de sessão.
    private void conferirIndisponibilidade(RespostaOperacao operacao) {
        assertFalse(operacao.isSucesso());
        assertEquals("SERVICO_INDISPONIVEL", operacao.getCodigo());
        assertEquals("Servico indisponivel. Tente novamente.", operacao.getMensagem());
        assertNull(operacao.getDados());
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeFalhar() throws Exception {
        // IOException representa falhas de transporte, incluindo timeouts HTTP.
        ServicoLogin servico = new ServicoLogin(new ClienteNodeIndisponivel());

        conferirIndisponibilidade(servico.entrar(LOGIN_JSON));
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeEnviarJsonMalformado() throws Exception {
        // HTTP 200 não é suficiente se o corpo não puder ser interpretado como JSON.
        conferirIndisponibilidade(executarLoginComResposta(200, "Resposta quebrada."));
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeEnviarLista() throws Exception {
        // Uma lista é JSON válido, mas não é o objeto de sessão definido no contrato.
        conferirIndisponibilidade(executarLoginComResposta(200, "[]"));
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeEnviarCorpoEmBranco() throws Exception {
        // Uma resposta sem conteúdo útil não pode confirmar a autenticação.
        conferirIndisponibilidade(executarLoginComResposta(200, "   "));
    }

    @Test
    void retornarIndisponibilidadeQuandoSessaoNaoTiverToken() throws Exception {
        // Dados de usuário sem token não formam a sessão esperada pelo aplicativo.
        conferirIndisponibilidade(executarLoginComResposta(200,
                "{\"usuario\":{\"id\":\"usuario-123\"}}"));
    }

    @Test
    void retornarIndisponibilidadeQuandoTokenForNumerico() throws Exception {
        // O token precisa chegar como texto, sem conversão automática de números.
        conferirIndisponibilidade(executarLoginComResposta(200,
                "{\"token\":123,\"usuario\":{\"id\":\"usuario-123\"}}"));
    }

    @Test
    void retornarIndisponibilidadeQuandoTokenEstiverEmBranco() throws Exception {
        // Um token textual vazio ou composto só de espaços também é inválido.
        conferirIndisponibilidade(executarLoginComResposta(200,
                "{\"token\":\"   \",\"usuario\":{\"id\":\"usuario-123\"}}"));
    }

    @Test
    void retornarIndisponibilidadeQuandoSessaoNaoTiverUsuario() throws Exception {
        // O contrato exige tanto o token quanto o objeto com os dados do usuário.
        conferirIndisponibilidade(executarLoginComResposta(200,
                "{\"token\":\"token-simulado\"}"));
    }

    @Test
    void retornarIndisponibilidadeQuandoUsuarioNaoForObjeto() throws Exception {
        // Texto no lugar de usuario não atende à estrutura da sessão.
        conferirIndisponibilidade(executarLoginComResposta(200,
                "{\"token\":\"token-simulado\",\"usuario\":\"Ana\"}"));
    }

    @Test
    void preservarRecusaDeCredenciaisDoNode() throws Exception {
        // HTTP 401 com mensagem válida é recusa de credenciais, não indisponibilidade.
        RespostaOperacao operacao = executarLoginComResposta(401,
                "{\"erro\":\"Email ou senha incorretos.\"}");

        assertFalse(operacao.isSucesso());
        assertEquals("OPERACAO_RECUSADA", operacao.getCodigo());
        assertEquals("Email ou senha incorretos.", operacao.getMensagem());
        assertNull(operacao.getDados());
    }

    @Test
    void retornarIndisponibilidadeQuandoRecusaNaoTiverMensagemValida() throws Exception {
        // Não apresenta ao aplicativo uma recusa sem a mensagem textual prevista.
        conferirIndisponibilidade(executarLoginComResposta(401, "{\"erro\":123}"));
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeResponderErro500SemJson() throws Exception {
        // Falhas do servidor podem trazer texto; não é necessário interpretar esse corpo.
        conferirIndisponibilidade(executarLoginComResposta(500, "Falha interna simulada."));
    }

    @Test
    void preservarInterrupcaoDaThread() throws Exception {
        // A supervisora precisa receber a exceção e encontrar a interrupção ainda marcada.
        ServicoLogin servico = new ServicoLogin(new ClienteNodeInterrompido());

        try {
            assertThrows(InterruptedException.class, () -> servico.entrar(LOGIN_JSON));
            assertTrue(Thread.currentThread().isInterrupted());
        } finally {
            // Limpa o sinal somente no teste, sem interferir nos próximos cenários do JUnit.
            Thread.interrupted();
        }
    }
}
