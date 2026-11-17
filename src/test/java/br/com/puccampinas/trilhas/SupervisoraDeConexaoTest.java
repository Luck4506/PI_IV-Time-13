package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.net.URI;
import java.util.concurrent.atomic.AtomicReference;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.InetAddress;
import java.util.ArrayList;
import java.io.BufferedWriter;
import java.io.BufferedReader;
import java.io.OutputStreamWriter;
import java.io.InputStreamReader;
import static org.junit.jupiter.api.Assertions.*;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;

// Integra TCP e HTTP locais com Node simulado; não acessa Flutter nem bancos reais.
public class SupervisoraDeConexaoTest {

    @Test
    void encaminharCadastroValidoAoNodeEDevolverRespostaAoCliente() throws Exception {
        // Confere envio ao HTTP, resposta pelo TCP e encerramento após EOF do cliente.
        HttpServer servidor = HttpServer.create(
                              new InetSocketAddress("127.0.0.1", 0),
                              0
        );

        String cadastroJson = """
            {
                "tipo": "VALIDAR_CADASTRO",
                "nome": "Jacarta Silva",
                "dataNascimento": "2009-08-15",
                "email": "jacarta@example.com",
                "senha": "Abcde12!",
                "perfil": 1,
                "anoEscolar": 2,
                "cadastroEducacional": false,
                "termosAceitos": true
            }
            """;

        // O protocolo exige uma linha física por mensagem, apesar do texto multilinha acima.
        cadastroJson = cadastroJson.replace("\n", "").replace("\r", "");

        AtomicReference<String> metodoRecebido = new AtomicReference<>();
        AtomicReference<String> tipoConteudoRecebido = new AtomicReference<>();
        AtomicReference<String> corpoRecebido = new AtomicReference<>();

        // Guarda a configuração global para restaurá-la no finally, inclusive em caso de falha.
        String enderecoNodeAnterior = System.getProperty("node.url");

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"mensagem\": \"Cadastro simulado.\"}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    metodoRecebido.set(troca.getRequestMethod());
                    tipoConteudoRecebido.set(troca.getRequestHeaders().getFirst("Content-Type"));
                    corpoRecebido.set(new String(troca.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);

                } finally {
                    troca.close();
                }
            });

            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);
            System.setProperty("node.url", uri.toString());

            // Os recursos deste try são fechados automaticamente ao sair do bloco.
            try (
                // Escuta conexões TCP locais; porta 0 pede uma porta disponível ao sistema.
                ServerSocket receptorDeConexoes = new ServerSocket(
                        0, 1, InetAddress.getByName("127.0.0.1")
                );
                // Representa o Flutter e se conecta à porta escolhida acima.
                Socket cliente = new Socket(
                        "127.0.0.1", receptorDeConexoes.getLocalPort()
                );
                // Aceita a conexão: este socket é o lado do servidor na mesma conversa.
                Socket conexaoDoServidor = receptorDeConexoes.accept()
            ) {
                // Uma leitura sem resposta falha após 5 segundos, em vez de esperar sem limite.
                cliente.setSoTimeout(5000);

                // Lista compartilhada na qual a supervisora registra e remove seu Parceiro.
                ArrayList<Parceiro> usuarios = new ArrayList<>();
                // Entrega à supervisora o lado do servidor; o teste fica com o lado do cliente.
                SupervisoraDeConexao supervisora = new SupervisoraDeConexao(conexaoDoServidor, usuarios);

                // Executa run() em outra thread, deixando o teste livre para enviar a mensagem.
                supervisora.start();

                BufferedWriter transmissor = new BufferedWriter(
                        new OutputStreamWriter(cliente.getOutputStream(), StandardCharsets.UTF_8)
                );

                BufferedReader receptor = new BufferedReader(
                        new InputStreamReader(cliente.getInputStream(), StandardCharsets.UTF_8)
                );

                // Envia o cadastro em uma linha; flush libera os dados guardados no buffer.
                transmissor.write(cadastroJson);
                transmissor.newLine();
                transmissor.flush();

                // Aguarda a resposta que a supervisora devolverá pelo TCP.
                String respostaJson = receptor.readLine();

                // null indicaria conexão encerrada sem uma linha de resposta.
                assertNotNull(respostaJson);

                // Interpreta o texto recebido pelo TCP para consultar os campos do JSON.
                JsonObject json = JsonParser.parseString(respostaJson).getAsJsonObject();

                // Confere o resultado da operação montado pelo Java.
                assertTrue(json.get("sucesso").getAsBoolean());
                assertEquals("CADASTRO_REALIZADO", json.get("codigo").getAsString());
                // dados guarda o objeto devolvido pelo Node simulado, que contém sua própria mensagem.
                assertEquals(
                        "Cadastro simulado.",
                        json.getAsJsonObject("dados").get("mensagem").getAsString()
                );

                // Confere o método HTTP e o formato do conteúdo enviado pelo Java.
                assertEquals("POST", metodoRecebido.get());
                assertEquals("application/json", tipoConteudoRecebido.get());

                assertNotNull(corpoRecebido.get());
                JsonObject cadastroEnviado = JsonParser.parseString(corpoRecebido.get()).getAsJsonObject();

                // O tipo identifica a operacao TCP e nao deve seguir no corpo HTTP.
                assertFalse(cadastroEnviado.has("tipo"));
                assertEquals("Jacarta Silva", cadastroEnviado.get("nome").getAsString());
                assertEquals(1, cadastroEnviado.get("perfil").getAsInt());
                assertEquals(2, cadastroEnviado.get("anoEscolar").getAsInt());

                // Este aluno nao possui vinculo educacional nem campos de professor.
                assertFalse(cadastroEnviado.has("codProfessor"));
                assertFalse(cadastroEnviado.has("codigoEscola"));
                assertFalse(cadastroEnviado.has("codigoTurma"));

                // Sinaliza que o cliente nao enviara mais mensagens; o Servidor ira receber EOF.
                cliente.shutdownOutput();

                // Aguarda ate 5 segundos para a supervisora concluir sua execucao e o finally.
                supervisora.join(5000);

                assertFalse(supervisora.isAlive(), "A supervisora deveria ter encerrado.");

                // Confere a remocao do parceiro usando o mesmo bloqueio da supervisora.
                synchronized (usuarios) {
                    assertTrue(usuarios.isEmpty(), "O parceiro deveria ter sido removido.");
                }
            }

        } finally {
            if(enderecoNodeAnterior == null) {
                System.clearProperty("node.url");
            } else {
                System.setProperty("node.url", enderecoNodeAnterior);
            }

            servidor.stop(0);
        }
    }

    @Test
    void rejeitarCadastroInvalidoSemEncaminharAoNode() throws Exception {
        // Somente o e-mail é inválido; a recusa deve voltar pelo TCP sem chamar o HTTP.
        HttpServer servidor = HttpServer.create(
                new InetSocketAddress("127.0.0.1", 0),
                0
        );

        String cadastroJson = """
            {
                "tipo": "VALIDAR_CADASTRO",
                "nome": "Jacarta Silva",
                "dataNascimento": "2009-08-15",
                "email": "jacarta",
                "senha": "Abcde12!",
                "perfil": 1,
                "anoEscolar": 2,
                "cadastroEducacional": false,
                "termosAceitos": true
            }
            """;

        cadastroJson = cadastroJson.replace("\n", "").replace("\r", "");

        AtomicReference<String> metodoRecebido = new AtomicReference<>();
        AtomicReference<String> tipoConteudoRecebido = new AtomicReference<>();
        AtomicReference<String> corpoRecebido = new AtomicReference<>();

        String enderecoNodeAnterior = System.getProperty("node.url");

        try {
            servidor.createContext("/api/auth/cadastro", troca -> {
                try {
                    String respostaJson = "{\"mensagem\": \"Cadastro simulado.\"}";
                    byte[] respostaBytes = respostaJson.getBytes(StandardCharsets.UTF_8);

                    metodoRecebido.set(troca.getRequestMethod());
                    tipoConteudoRecebido.set(troca.getRequestHeaders().getFirst("Content-Type"));
                    corpoRecebido.set(new String(troca.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));

                    troca.sendResponseHeaders(201, respostaBytes.length);
                    troca.getResponseBody().write(respostaBytes);

                } finally {
                    troca.close();
                }
            });

            servidor.start();
            int porta = servidor.getAddress().getPort();
            URI uri = URI.create("http://127.0.0.1:" + porta);
            System.setProperty("node.url", uri.toString());

            // Os recursos deste try são fechados automaticamente ao sair do bloco.
            try (
                    // Escuta conexões TCP locais; porta 0 pede uma porta disponível ao sistema.
                    ServerSocket receptorDeConexoes = new ServerSocket(
                            0, 1, InetAddress.getByName("127.0.0.1")
                    );
                    // Representa o Flutter e se conecta à porta escolhida acima.
                    Socket cliente = new Socket(
                            "127.0.0.1", receptorDeConexoes.getLocalPort()
                    );
                    // Aceita a conexão: este socket é o lado do servidor na mesma conversa.
                    Socket conexaoDoServidor = receptorDeConexoes.accept()
            ) {
                // Uma leitura sem resposta falha após 5 segundos, em vez de esperar sem limite.
                cliente.setSoTimeout(5000);

                // Lista compartilhada na qual a supervisora registra e remove seu Parceiro.
                ArrayList<Parceiro> usuarios = new ArrayList<>();
                // Entrega à supervisora o lado do servidor; o teste fica com o lado do cliente.
                SupervisoraDeConexao supervisora = new SupervisoraDeConexao(conexaoDoServidor, usuarios);

                // Executa run() em outra thread, deixando o teste livre para enviar a mensagem.
                supervisora.start();

                BufferedWriter transmissor = new BufferedWriter(
                        new OutputStreamWriter(cliente.getOutputStream(), StandardCharsets.UTF_8)
                );

                BufferedReader receptor = new BufferedReader(
                        new InputStreamReader(cliente.getInputStream(), StandardCharsets.UTF_8)
                );

                // Envia o cadastro em uma linha; flush libera os dados guardados no buffer.
                transmissor.write(cadastroJson);
                transmissor.newLine();
                transmissor.flush();

                // Aguarda a resposta que a supervisora devolverá pelo TCP.
                String respostaJson = receptor.readLine();

                // null indicaria conexão encerrada sem uma linha de resposta.
                assertNotNull(respostaJson);

                JsonObject json = JsonParser.parseString(respostaJson).getAsJsonObject();

                // O Java recusou o cadastro antes de executar qualquer operação no Node.
                assertFalse(json.get("sucesso").getAsBoolean());
                assertEquals("CADASTRO_INVALIDO", json.get("codigo").getAsString());
                assertTrue(json.get("dados").isJsonNull());

                // Nenhuma requisição deve ter chegado ao Servidor HTTP simulado.
                assertNull(metodoRecebido.get());
                assertNull(tipoConteudoRecebido.get());
                assertNull(corpoRecebido.get());

                // Sinaliza que o cliente nao enviara mais mensagens; o Servidor ira receber EOF.
                cliente.shutdownOutput();

                // Aguarda ate 5 segundos para a supervisora concluir sua execucao e o finally.
                supervisora.join(5000);

                assertFalse(supervisora.isAlive(), "A supervisora deveria ter encerrado.");

                // Confere a remocao do parceiro usando o mesmo bloqueio da supervisora.
                synchronized (usuarios) {
                    assertTrue(usuarios.isEmpty(), "O parceiro deveria ter sido removido.");
                }
            }

        } finally {
            if(enderecoNodeAnterior == null) {
                System.clearProperty("node.url");
            } else {
                System.setProperty("node.url", enderecoNodeAnterior);
            }

            servidor.stop(0);
        }
    }
}
