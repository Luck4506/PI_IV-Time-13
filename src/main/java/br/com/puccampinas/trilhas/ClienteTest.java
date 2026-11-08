package br.com.puccampinas.trilhas;

import java.io.*;
import java.net.*;

public class ClienteTest {
    public static void main(String[] args) {
        try {
            Socket conexao = new Socket("localhost", 3000);
            ObjectOutputStream transmissor = new ObjectOutputStream(conexao.getOutputStream());
            ObjectInputStream receptor = new ObjectInputStream(conexao.getInputStream());

            System.out.println("Conectado ao servidor! Digite 'Hello' ou qualquer outra coisa ('sair' para encerrar):");

            for(;;) {
                System.out.print("Você > ");
                String texto = Teclado.getUmString();

                if(texto == null || texto.equalsIgnoreCase("sair")) {
                    transmissor.writeObject(new PedidoParaSair());
                    transmissor.flush();
                    break;
                }

                // Envia comunicado vazio para o servidor
                transmissor.writeObject(new Comunicado());
                transmissor.flush();

                // Fica esperando a resposta do servidor e imprime na tela
                Comunicado resposta = (Comunicado) receptor.readObject();
                System.out.println("Comunicado recebido de volta.");
            }

            conexao.close();
            System.out.println("Conexão encerrada.");

        } catch (Exception e) {
            System.err.println("Erro na conexão: " + e.getMessage());
        }
    }
}