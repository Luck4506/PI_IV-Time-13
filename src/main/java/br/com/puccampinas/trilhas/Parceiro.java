// Autoria de Henrique RA 25005651 com base nos videos do professor Andre

package br.com.puccampinas.trilhas;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.net.Socket;
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

    // Nomes preservados da referência: receba envia ao cliente; envie recebe dele.
    public void receba(String x) throws Exception {

        if(x == null) throw new Exception("Comunicado ausente.");

        try {
            // Mantém conteúdo, delimitador e flush juntos para não misturar envios simultâneos.
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

    // Consulta a próxima linha sem consumi-la; o semáforo protege leitura e mensagem guardada.
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

    // Consome a linha guardada ou lê outra; null indica fim da entrada (EOF).
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
