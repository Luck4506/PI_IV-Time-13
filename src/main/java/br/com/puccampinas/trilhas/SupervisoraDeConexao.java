package br.com.puccampinas.trilhas;

import java.io.*;
import java.net.*;
import java.util.*;

/*
Documentacao...
*/

public class SupervisoraDeConexao extends Thread {

    private Parceiro usuario;
    private Socket conexao;
    private ArrayList<Parceiro> usuarios;

    public SupervisoraDeConexao(Socket conexao,
                                ArrayList<Parceiro> usuarios)
                                throws Exception {

        if(conexao == null) throw new Exception("Conexao ausente.");

        if(usuarios == null) throw new Exception("Usuarios ausentes.");

        this.conexao = conexao;
        this.usuarios = usuarios;
    }

    public void run() {

        ObjectOutputStream transmissor;
        try {
            transmissor = new ObjectOutputStream(
                          this.conexao.getOutputStream());
        }
        catch(Exception erro) {
            return;
        }

        ObjectInputStream receptor = null;
        try {
            receptor = new ObjectInputStream(
                       this.conexao.getInputStream());
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

            // Teste
            for(;;) {
                Comunicado comunicado = usuario.envie();

                if(comunicado instanceof PedidoParaSair) {
                    break;
                }
                else {
                    usuario.receba(comunicado);
                }
            }
        }
        catch(Exception erro) {}
        finally {
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
