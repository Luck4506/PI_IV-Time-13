package br.com.puccampinas.trilhas;

import java.io.*;
import java.net.*;
import java.util.*;
import java.nio.charset.StandardCharsets;

public class SupervisoraDeConexao extends Thread {

    private Parceiro usuario;
    private Socket conexao;
    private ArrayList<Parceiro> usuarios;
    private final ServicoCadastro servicoCadastro;

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

        this.conexao = conexao;
        this.usuarios = usuarios;
    }

    public void run() {

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
            this.usuario = new Parceiro(this.conexao,
                                        receptor,
                                        transmissor);
        }
        catch(Exception erro) {}

        try {
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
                        Comunicado pedidoRecebido = conversor.converterPedido(comunicado);

                        // Login já é reconhecido, mas o encaminhamento ao Node só atende cadastro.
                        if(!(pedidoRecebido instanceof PedidoDeCadastro)) {
                            throw new Exception("Encaminhamento deste tipo de pedido ainda nao implementado.");
                        }
                        PedidoDeCadastro pedido = (PedidoDeCadastro) pedidoRecebido;

                        // Encaminha os valores tratados e aguarda o resultado do Node antes de responder.
                        String cadastroJson = conversor.converterCadastroParaNode(pedido);
                        resultado = servicoCadastro.cadastrar(cadastroJson);
                    } catch (InterruptedException erro) {
                        // Preserva o sinal de interrupção e sai do laço, executando o finally externo.
                        Thread.currentThread().interrupt();
                        break;
                    } catch (Exception erro) {
                        // Por enquanto, este código também cobre operações sem encaminhamento implementado.
                        resultado = new RespostaOperacao(false, "CADASTRO_INVALIDO", erro.getMessage(), null);
                    }

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
