package br.com.puccampinas.trilhas;

import java.io.*;
import java.net.*;
import java.util.*;
import java.nio.charset.StandardCharsets;

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

            // Teste
            for(;;) {
                String comunicado = usuario.envie();

                if(comunicado == null) {
                    break;
                }
                else {
                    ConversorJson conversor = new ConversorJson();
                    ResultadoValidacao resultado;

                    try {
                        conversor.converterPedido(comunicado);
                        resultado = new ResultadoValidacao(true, "Campos validos.");
                    } catch (Exception erro) {
                        resultado = new ResultadoValidacao(false, erro.getMessage());
                    }

                    String respostaJson = conversor.converterResultado(resultado);
                    usuario.receba(respostaJson);
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
