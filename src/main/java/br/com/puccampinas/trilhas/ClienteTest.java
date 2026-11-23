// Autoria de Henrique RA 25005651

package br.com.puccampinas.trilhas;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class ClienteTest {
    public static void main(String[] args) {
        // Cliente temporário para testar uma mensagem por linha, em UTF-8.
        try (Socket conexao = new Socket("localhost", 3000)) {
            BufferedWriter transmissor = new BufferedWriter(new OutputStreamWriter(
                    conexao.getOutputStream(), StandardCharsets.UTF_8));
            BufferedReader receptor = new BufferedReader(new InputStreamReader(
                    conexao.getInputStream(), StandardCharsets.UTF_8));

            System.out.println("Conectado! Digite uma linha de texto ou JSON ('sair' para encerrar):");

            for(;;) {
                System.out.print("Você > ");
                String texto = Teclado.getUmString();

                if(texto == null || texto.equalsIgnoreCase("sair")) {
                    // Ao sair do try, o socket é fechado e o servidor recebe EOF.
                    break;
                }

                // A quebra de linha delimita a mensagem; flush efetiva o envio.
                transmissor.write(texto);
                transmissor.newLine();
                transmissor.flush();

                String resposta = receptor.readLine();
                if(resposta == null) {
                    System.out.println("O servidor encerrou a conexão.");
                    break;
                }
                System.out.println("Servidor > " + resposta);
            }

        } catch (Exception e) {
            System.err.println("Erro na conexão: " + e.getMessage());
        }
        System.out.println("Conexão encerrada.");
    }
}
