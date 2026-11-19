package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.net.URI;
import java.net.http.HttpResponse;
import static org.junit.jupiter.api.Assertions.*;
import java.util.concurrent.atomic.AtomicReference;

// Verifica transporte HTTP e interpretação das respostas usando um Node simulado localmente.
public class ClienteNodeTest {

    @Test
    void enviarCadastroAoNode() throws Exception {
        // Simula o Node localmente; porta 0 escolhe uma porta disponível.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
                              );

        // Pedido fictício: este teste verifica HTTP, não as regras de cadastro.
        String cadastroJson = "{\"token\": \"token-simulado\", \"usuario\": {\"id\": \"usuario-123\"}}";
        // Compartilham o pedido capturado na thread do servidor com a thread do teste.
        AtomicReference<String> metodoRecebido = new AtomicReference<>();
        AtomicReference<String> tipoConteudoRecebido = new AtomicReference<>();
        AtomicReference<String> corpoRecebido = new AtomicReference<>();

        try {
            // Registra o que fazer quando uma requisição chegar a esta rota.
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"token\": \"token-simulado\", \"usuario\": {\"id\": \"usuario-123\"}}";
                    // HTTP transmite bytes; o tamanho informado será o de bytes, não de letras.
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    // Captura o pedido antes de responder, para evitar verificações prematuras.
                    metodoRecebido.set(troca.getRequestMethod());
                    tipoConteudoRecebido.set(troca.getRequestHeaders().getFirst("Content-Type"));
                    corpoRecebido.set(new String(troca.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));

                    // Devolve uma resposta fixa: 201 é o status HTTP de criação.
                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);

                } finally {
                    // Fecha somente esta requisição/resposta, mantendo o servidor disponível.
                    troca.close();
                }
            });

            // Inicia o servidor e usa a porta escolhida pelo sistema na URL do cliente.
            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);
            // Executa o método real que queremos testar contra o servidor simulado.
            HttpResponse<String> resposta = new ClienteNode(uri).cadastrar(cadastroJson);

            RespostaOperacao operacao = new ConversorRespostaNode().converterCadastro(resposta);

            // Confere a resposta recebida pelo cliente.
            assertEquals(201, resposta.statusCode());
            assertEquals("{\"token\": \"token-simulado\", \"usuario\": {\"id\": \"usuario-123\"}}",
                    resposta.body()
            );
            // Confere o pedido que efetivamente chegou ao servidor.
            assertEquals("POST", metodoRecebido.get());
            assertEquals("application/json", tipoConteudoRecebido.get());
            assertEquals(cadastroJson, corpoRecebido.get());

            assertTrue(operacao.isSucesso());
            assertEquals("CADASTRO_REALIZADO", operacao.getCodigo());
            assertEquals("Cadastro realizado.", operacao.getMensagem());
            // Confere a sessão preservada nos dados da operação.
            assertEquals("token-simulado", operacao.getDados().get("token").getAsString());
            assertEquals(
                    "usuario-123",
                    operacao.getDados().getAsJsonObject("usuario").get("id").getAsString()
            );

        } finally {
            // Libera o servidor e sua porta mesmo se o teste falhar.
            servidor.stop(0);
        }
    }

    @Test
    void preservarRespostaDeCadastroDuplicado() throws Exception {
        // HTTP 409 deve manter a mensagem de recusa e não retornar dados de sucesso.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
                              );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"erro\": \"Este email ja esta cadastrado.\"}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(409, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
                    troca.close();
                }
            });

            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);
            HttpResponse<String> resposta = new ClienteNode(uri).cadastrar(cadastroJson);

            RespostaOperacao operacao = new ConversorRespostaNode().converterCadastro(resposta);

            assertEquals(409, resposta.statusCode());
            assertEquals("{\"erro\": \"Este email ja esta cadastrado.\"}", resposta.body());

            assertFalse(operacao.isSucesso());
            assertEquals("OPERACAO_RECUSADA", operacao.getCodigo());
            assertEquals("Este email ja esta cadastrado.", operacao.getMensagem());
            assertNull(operacao.getDados());
        } finally {
            servidor.stop(0);
        }
    }

    @Test
    void tratarErro500SemExigirJson() throws Exception {
        // Uma falha HTTP 500 deve virar indisponibilidade mesmo quando o corpo não é JSON.
        HttpServer servidor = HttpServer.create(
                new InetSocketAddress("127.0.0.1", 0),
                0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String bodyResposta = "Falha interna.";
                    byte[] respostaBytes = bodyResposta.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(500, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
                    troca.close();
                }
            });

            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);
            HttpResponse<String> resposta = new ClienteNode(uri).cadastrar(cadastroJson);

            RespostaOperacao operacao = new ConversorRespostaNode().converterCadastro(resposta);

            assertEquals(500, resposta.statusCode());
            assertEquals("Falha interna.", resposta.body());

            assertFalse(operacao.isSucesso());
            assertEquals("SERVICO_INDISPONIVEL", operacao.getCodigo());
            assertEquals("Servico indisponivel. Tente novamente.", operacao.getMensagem());
            assertNull(operacao.getDados());
        } finally {
            servidor.stop(0);
        }
    }

}
