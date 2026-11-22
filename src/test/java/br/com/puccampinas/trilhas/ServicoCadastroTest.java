package br.com.puccampinas.trilhas;
import java.net.URI;
import java.net.http.HttpResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.net.InetSocketAddress;
import com.sun.net.httpserver.HttpServer;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

// Isola falhas de comunicação e de resposta sem depender do Node real ou dos bancos.
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
        // O cliente substituto lança IOException para simular uma falha de transporte.
        ServicoCadastro servico = new ServicoCadastro(new ClienteNodeIndisponivel());
        RespostaOperacao operacao = servico.cadastrar("{\"fruta\": \"Abacate\"}");

        assertFalse(operacao.isSucesso());
        assertEquals("SERVICO_INDISPONIVEL", operacao.getCodigo());
        assertEquals("Servico indisponivel. Tente novamente.", operacao.getMensagem());
        assertNull(operacao.getDados());
    }

    @Test
    void retornarIndisponibilidadeQuandoNodeEnviarRespostaInvalida() throws Exception {
        // Um status 201 com corpo inválido não deve ser apresentado como sucesso.
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
        // A interrupção precisa ser propagada e continuar marcada na thread chamadora.
        ServicoCadastro servico = new ServicoCadastro(new ClienteNodeInterrompido());
        try {
            assertThrows(
                    InterruptedException.class,
                    () -> servico.cadastrar("{\"fruta\":\"Abacate\"}")
            );
            assertTrue(Thread.currentThread().isInterrupted());
        } finally {
            // Limpa o sinal somente no teste, para não afetar os próximos cenários do JUnit.
            Thread.interrupted();
        }
    }

    @Test
    void retornarIndisponibilidadeQuandoCadastroNaoTiverToken() throws Exception {
        // Mesmo com HTTP 201, usuário sem token não completa a sessão esperada.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"usuario\": {\"id\": \"usuario-123\"}}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
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
    void retornarIndisponibilidadeQuandoTokenDoCadastroForNumerico() throws Exception {
        // O token deve ser texto; um número não pode ser convertido automaticamente.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"token\": 123, \"usuario\": {\"id\": \"usuario-123\"}}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
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
    void retornarIndisponibilidadeQuandoTokenDoCadastroEstiverEmBranco() throws Exception {
        // Um token com apenas espaços não permite confirmar a sessão do cadastro.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"token\": \"   \", \"usuario\": {\"id\": \"usuario-123\"}}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
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
    void retornarIndisponibilidadeQuandoCadastroNaoTiverUsuario() throws Exception {
        // Token sem o objeto de usuário também é uma resposta incompleta.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"token\": \"token-simulado\"}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
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
    void retornarIndisponibilidadeQuandoUsuarioDoCadastroNaoForObjeto() throws Exception {
        // O campo usuario deve ser um objeto JSON, não um texto com o nome.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = "{\"nome\": \"Jefferson\"}";

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"token\": \"token-simulado\", \"usuario\": \"Jefferson\"}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);
                } finally {
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

}
