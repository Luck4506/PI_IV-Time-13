// Autoria de Henrique RA 25005651 com base nos videos do professor Andre

package br.com.puccampinas.trilhas;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

// Atende uma conexão do aplicativo e coordena os pedidos de cadastro e login.
public class SupervisoraDeConexao extends Thread {

    private Parceiro usuario;
    private Socket conexao;
    private ArrayList<Parceiro> usuarios;
    private final ServicoCadastro servicoCadastro;
    private final ServicoLogin servicoLogin;

    public SupervisoraDeConexao(Socket conexao,
                                ArrayList<Parceiro> usuarios)
                                throws Exception {

        if(conexao == null) throw new Exception("Conexao ausente.");

        if(usuarios == null) throw new Exception("Usuarios ausentes.");

        // -Dnode.url configura o destino HTTP; testes usam o endereço do Node simulado.
        String enderecoTexto = System.getProperty("node.url", "http://127.0.0.1:3001");
        URI enderecoInterpretado = URI.create(enderecoTexto);
        ClienteNode clienteNode = new ClienteNode(enderecoInterpretado);
        this.servicoCadastro = new ServicoCadastro(clienteNode);
        this.servicoLogin = new ServicoLogin(clienteNode);

        this.conexao = conexao;
        this.usuarios = usuarios;
    }

    public void run() {

        // Prepara a saída e a entrada de texto em UTF-8 para a troca de JSON.
        BufferedWriter transmissor;
        try {
            transmissor = new BufferedWriter(
                          new OutputStreamWriter(
                          this.conexao.getOutputStream(), StandardCharsets.UTF_8));
        }
        catch(Exception erro) {
            return;
        }

        BufferedReader receptor = null;
        try {
            receptor = new BufferedReader(
                       new InputStreamReader(
                       this.conexao.getInputStream(), StandardCharsets.UTF_8));
        }
        catch(Exception erro) {
            try {
                transmissor.close();
            }
            catch(Exception falha) {}

            return;
        }

        try {
            // Reúne o socket e os streams em um Parceiro para ler e responder ao cliente.
            this.usuario = new Parceiro(this.conexao,
                                        receptor,
                                        transmissor);
        }
        catch(Exception erro) {}

        try {
            // Registra o parceiro na lista compartilhada usada ao desativar o servidor.
            synchronized(this.usuarios) {
                this.usuarios.add(this.usuario);
            }

            // Processa uma mensagem JSON por linha até o cliente encerrar o envio (EOF).
            for(;;) {
                String comunicado = usuario.envie();

                if(comunicado == null) {
                    break;
                }
                else {
                    ConversorJson conversor = new ConversorJson();
                    RespostaOperacao resultado;

                    try {
                        // Interpreta o JSON recebido e valida os campos do pedido.
                        Comunicado pedidoRecebido = conversor.converterPedido(comunicado);

                        // Cada pedido segue para sua rota HTTP; o Java aguarda o resultado do Node.
                        if(pedidoRecebido instanceof PedidoDeCadastro) {
                            PedidoDeCadastro pedido = (PedidoDeCadastro) pedidoRecebido;
                            String cadastroJson = conversor.converterCadastroParaNode(pedido);
                            resultado = servicoCadastro.cadastrar(cadastroJson);
                        } else if(pedidoRecebido instanceof PedidoDeLogin) {
                            PedidoDeLogin pedido = (PedidoDeLogin) pedidoRecebido;
                            String loginJson = conversor.converterLoginParaNode(pedido);
                            resultado = servicoLogin.entrar(loginJson);
                        } else {
                            throw new Exception("Tipo de pedido sem tratamento.");
                        }
                    } catch (InterruptedException erro) {
                        // Preserva o sinal de interrupção e sai do laço, executando o finally externo.
                        Thread.currentThread().interrupt();
                        break;
                    } catch (Exception erro) {
                        // Recusa mensagens inválidas; falhas de transporte HTTP são tratadas pelos serviços.
                        resultado = new RespostaOperacao(false, "VALIDACAO_INVALIDA", erro.getMessage(), null);
                    }

                    // Converte o resultado em JSON e envia uma linha de resposta ao aplicativo.
                    String respostaJson = new ConversorRespostaNode().converterParaJson(resultado);
                    usuario.receba(respostaJson);
                }
            }
        }
        catch(Exception erro) {}
        finally {
            // Remove o parceiro da lista compartilhada e fecha os streams da conexão.
            try {
                synchronized(this.usuarios) {
                    this.usuarios.remove(this.usuario);
                }
                transmissor.close();
                receptor.close();
            }
            catch(Exception falha) {}
        }
    }
}
