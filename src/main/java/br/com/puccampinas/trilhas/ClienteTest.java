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
                    transmissor.writeObject("sair");
                    transmissor.flush();
                    break;
                }

                // Envia o que você digitou no console para o servidor
                transmissor.writeObject(texto);
                transmissor.flush();

                // Fica esperando a resposta do servidor e imprime na tela
                String resposta = (String) receptor.readObject();
                System.out.println("Servidor > " + resposta);
            }

            conexao.close();
            System.out.println("Conexão encerrada.");

        } catch (Exception e) {
            System.err.println("Erro na conexão: " + e.getMessage());
        }
    }
}