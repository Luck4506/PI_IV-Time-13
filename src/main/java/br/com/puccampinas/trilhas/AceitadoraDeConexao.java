// Autoria de Henrique RA 25005651 com base nos videos do professor Andre

package br.com.puccampinas.trilhas;

import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;

// Escuta a porta TCP e entrega cada conexão a uma supervisora em uma thread própria.
public class AceitadoraDeConexao extends Thread {

    private ServerSocket pedido;
    private ArrayList<Parceiro> usuarios;

    public AceitadoraDeConexao(String porta,
                               ArrayList<Parceiro> usuarios)
                               throws Exception {

        if(porta == null) throw new Exception("Porta ausente.");

        // Abre a porta em que o servidor recebe as conexões do aplicativo.
        try {
            this.pedido = new ServerSocket(Integer.parseInt(porta));
        }
        catch(Exception erro) {
            throw new Exception("Porta invalida.");
        }

        if(usuarios == null) throw new Exception("Usuarios ausentes.");

        this.usuarios = usuarios;
    }

    public void run() {

        for(;;) {
            Socket conexao = null;
            try {
                // Aguarda uma nova conexão antes de iniciar o atendimento.
                conexao = this.pedido.accept();
            }
            catch(Exception erro) {
                continue;
            }

            SupervisoraDeConexao supervisoraDeConexao = null;
            try {
                supervisoraDeConexao = new SupervisoraDeConexao(conexao, usuarios);
            }
            catch(Exception erro) {}

            // O atendimento roda em paralelo enquanto esta thread aguarda outros clientes.
            supervisoraDeConexao.start();
        }
    }
}
