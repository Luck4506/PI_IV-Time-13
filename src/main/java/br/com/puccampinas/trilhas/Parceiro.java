package br.com.puccampinas.trilhas;

import java.io.*;
import java.net.*;
import java.rmi.server.ExportException;
import java.util.*;
import java.util.concurrent.Semaphore;

public class Parceiro {

    private Socket conexao;
    // Streams de texto: a comunicação será feita com um JSON por linha.
    private BufferedReader receptor;
    private BufferedWriter transmissor;

    // Guarda a próxima mensagem em texto para consultar sem consumir.
    private String proximoComunicado = null;
    private Semaphore mutEx = new Semaphore(1, true);

    public Parceiro(Socket conexao,
                    BufferedReader receptor,
                    BufferedWriter transmissor)
                    throws Exception {

        if(conexao == null) throw new Exception("Conexao ausente.");

        if(receptor == null) throw new Exception("Receptor ausente.");

        if(transmissor == null) throw new Exception("Transmissor ausente.");

        this.conexao = conexao;
        this.receptor = receptor;
        this.transmissor = transmissor;
    }

    public void receba(String x) throws Exception {

        if(x == null) throw new Exception("Comunicado ausente.");

        try {
            synchronized(this.transmissor) {
                this.transmissor.write(x);
                this.transmissor.newLine();
                this.transmissor.flush();
            }
        }
        catch(IOException erro) {
            throw new Exception("Erro de transmissao.");
        }
    }

    public String espie() throws Exception {

        this.mutEx.acquireUninterruptibly();
        try {
            if(this.proximoComunicado == null)
                this.proximoComunicado = this.receptor.readLine();

            return this.proximoComunicado;
        }
        catch(Exception erro) {
            throw new Exception("Erro de recepcao.");
        }
        finally {
            this.mutEx.release();
        }
    }

    public String envie() throws Exception {

        this.mutEx.acquireUninterruptibly();
        try {
            if(this.proximoComunicado == null)
                this.proximoComunicado = this.receptor.readLine();

            String ret = this.proximoComunicado;
            this.proximoComunicado = null;
            return ret;
        }
        catch(Exception erro) {
            throw new Exception("Erro de recepcao.");
        }
        finally {
            this.mutEx.release();
        }
    }

    public void adeus() throws Exception {

        try {
            this.transmissor.close();
            this.receptor.close();
            this.conexao.close();
        }
        catch(Exception erro) {
            throw new Exception("Erro de desconexao.");
        }
    }
}
