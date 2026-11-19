package br.com.puccampinas.trilhas;
import java.net.URI;
import java.net.http.HttpClient;
import java.time.Duration;
import java.net.http.HttpResponse;
import java.net.http.HttpRequest;

// Encaminha operações ao Node.js por HTTP, sem acessar os bancos diretamente.
public class ClienteNode {
    private final URI enderecoBase;
    private final HttpClient clienteHttp;

    public ClienteNode(URI enderecoBase) throws Exception {
        if(enderecoBase == null) throw new Exception("Endereco invalido.");

        // O endereço recebido permite usar o Node real ou um servidor de teste.
        this.enderecoBase = enderecoBase;
        // Limita a espera para estabelecer a conexão.
        this.clienteHttp = HttpClient.newBuilder()
                           .connectTimeout(Duration.ofSeconds(5))
                           .build();
    }

    public HttpResponse<String> cadastrar(String cadastroJson) throws Exception {
        if(cadastroJson == null) throw new Exception("Json de cadastro invalido");

        // Prepara o POST JSON; o timeout abaixo limita a espera da requisição.
        HttpRequest requisicao = HttpRequest.newBuilder()
                                 .uri(enderecoBase.resolve("/api/auth/cadastro"))
                                 .timeout(Duration.ofSeconds(10))
                                 .header("Content-Type", "application/json")
                                 .POST(HttpRequest.BodyPublishers.ofString(cadastroJson))
                                 .build();

        // Aguarda a resposta e preserva status HTTP e corpo para análise posterior.
        return clienteHttp.send(requisicao, HttpResponse.BodyHandlers.ofString());
    }

    public HttpResponse<String> entrar(String loginJson) throws Exception {
        if(loginJson == null) throw new Exception("Json de login invalido");

        HttpRequest requisicao = HttpRequest.newBuilder()
                                 .uri(enderecoBase.resolve("/api/auth/login"))
                                 .timeout(Duration.ofSeconds(10))
                                 .header("Content-Type", "application/json")
                                 .POST(HttpRequest.BodyPublishers.ofString(loginJson))
                                 .build();

        return clienteHttp.send(requisicao, HttpResponse.BodyHandlers.ofString());
    }
}
