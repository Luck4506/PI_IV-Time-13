package br.com.puccampinas.trilhas;
import java.net.URI;
import java.net.http.HttpResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.net.InetSocketAddress;
import com.sun.net.httpserver.HttpServer;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class ServicoCadastroTest {

    private static class ClienteNodeIndisponivel extends ClienteNode {

        public ClienteNodeIndisponivel() throws Exception {
            super(URI.create("http://127.0.0.1"));
        }

        @Override
        public HttpResponse<String> cadastrar(String cadastroJson) throws Exception {
            throw new IOException("Falha simulada.");
        }
    }

    private static class ClienteNodeInterrompido extends ClienteNode {

        public ClienteNodeInterrompido() throws Exception {
            super(URI.create("http://127.0.0.1"));
        }

        @Override
        public HttpResponse<String> cadastrar(String cadastroJson) throws Exception {
            throw new InterruptedException("Falha simulada.");
        }
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeFalhar() throws Exception {
        ServicoCadastro servico = new ServicoCadastro(new ClienteNodeIndisponivel());
        RespostaOperacao operacao = servico.cadastrar("{\"fruta\": \"Abacate\"}");

        assertFalse(operacao.isSucesso());
        assertEquals("SERVICO_INDISPONIVEL", operacao.getCodigo());
        assertEquals("Servico indisponivel. Tente novamente.", operacao.getMensagem());
        assertNull(operacao.getDados());
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeEnviarRespostaInvalida() throws Exception {
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "Resposta quebrada.";
                    // HTTP transmite bytes; o tamanho informado será o de bytes, não de letras.
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    // Devolve uma resposta fixa: 201 é o status HTTP de criação.
                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);

                } finally {
                    // Fecha somente esta requisição/resposta, mantendo o servidor disponível.
                    troca.close();
                }
            });

            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);

            ServicoCadastro servico = new ServicoCadastro(new ClienteNode(uri));
            RespostaOperacao operacao = servico.cadastrar(cadastroJson);

            assertFalse(operacao.isSucesso());
            assertEquals("SERVICO_INDISPONIVEL", operacao.getCodigo());
            assertEquals("Servico indisponivel. Tente novamente.", operacao.getMensagem());
            assertNull(operacao.getDados());
        }
        finally {
            servidor.stop(0);
        }
    }

    @Test
    void preservarInterrupcaoDaThread() throws Exception {
        ServicoCadastro servico = new ServicoCadastro(new ClienteNodeInterrompido());
        try {
            assertThrows(
                    InterruptedException.class,
                    () -> servico.cadastrar("{\"fruta\":\"Abacate\"}")
            );
            assertTrue(Thread.currentThread().isInterrupted());
        } finally {
            Thread.interrupted();
        }
    }

}
