// Autoria de Henrique RA 25005651 com base nos videos do professor Andre

package br.com.puccampinas.trilhas;

import java.util.*;

// Inicia o servidor TCP e controla seu encerramento pelo terminal.
public class Servidor {

    public static final String PORTA_PADRAO = "3000";

    public static void main(String[] args) {

        if(args.length > 1) {
            System.err.println("Uso esperado: java Servidor [PORTA]\n");
            return;
        }

        // Usa a porta padrão, a menos que outra seja informada na linha de comando.
        String porta = Servidor.PORTA_PADRAO;

        if(args.length == 1) porta = args[0];

        // Compartilha a lista de conexões ativas com a aceitadora e as supervisoras.
        ArrayList<Parceiro> usuarios = new ArrayList<Parceiro>();

        // Inicia a escuta em outra thread para manter o terminal disponível.
        AceitadoraDeConexao aceitadoraDeConexao = null;
        try {
            aceitadoraDeConexao = new AceitadoraDeConexao(porta, usuarios);
            aceitadoraDeConexao.start();
        }
        catch(Exception erro) {
            System.err.println("Escolha uma porta apropriada e liberada para uso!\n");
            return;
        }

        for(;;) {
            System.out.println("O servidor esta ativo! Para desativa-lo,");
            System.out.println("use o comando \"desativar\"\n");
            System.out.print("> ");

            String comando = null;
            try {
                comando = Teclado.getUmString();
            }
            catch(Exception erro) {}

            if(comando.toLowerCase().equals("desativar")) {
                // Fecha as conexões ativas antes de encerrar o processo.
                synchronized(usuarios) {
                    for(Parceiro usuario : usuarios) {
                        try {
                            usuario.adeus();
                        }
                        catch(Exception erro) {}
                    }
                }

                System.out.println("O servidor foi desativado!\n");
                System.exit(0);
            }
            else
                System.err.println("Comando invalido!\n");
        }
    }
}