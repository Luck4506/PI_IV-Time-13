// Autoria de Sofia de Sousa RA 25005435

package br.com.puccampinas.trilhas;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;

// Verifica formato, presença e normalização dos campos; não autentica contas.
public class PedidoDeLoginTest {

    @Test
    void loginValido() throws Exception {
        PedidoDeLogin pedido = new PedidoDeLogin("ana@example.com", "qualquer");

        assertEquals("ana@example.com", pedido.getEmail());
        assertEquals("qualquer", pedido.getSenha());
    }

    @Test
    void loginGuardaEmailSemEspacos() throws Exception {
        PedidoDeLogin pedido = new PedidoDeLogin("  ana@example.com  ", "Abcde12!");

        assertEquals("ana@example.com", pedido.getEmail());
    }

    @Test
    void loginSemEmail() {
        Exception excecao = assertThrows(Exception.class,
                () -> new PedidoDeLogin(null, "Abcde12!"));

        assertEquals("Informe um endereço de email válido.", excecao.getMessage());
    }

    @Test
    void loginComEmailInvalido() {
        Exception excecao = assertThrows(Exception.class,
                () -> new PedidoDeLogin("ana.example.com", "Abcde12!"));

        assertEquals("Informe um endereço de email válido.", excecao.getMessage());
    }

    @Test
    void loginSemSenha() {
        Exception excecao = assertThrows(Exception.class,
                () -> new PedidoDeLogin("ana@example.com", null));

        assertEquals("Informe sua senha.", excecao.getMessage());
    }

    @Test
    void loginComSenhaVazia() {
        Exception excecao = assertThrows(Exception.class,
                () -> new PedidoDeLogin("ana@example.com", ""));

        assertEquals("Informe sua senha.", excecao.getMessage());
    }
}
