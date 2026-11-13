package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.time.LocalDate;

// Cada cenário INVALIDO altera apenas um campo e confere a mensagem recebida.
public class PedidoDeCadastroTest {

    @Test
    void cadastroEstudanteValido() throws Exception {
        PedidoDeCadastro pedido = new PedidoDeCadastro("Ana Silva",
                                                LocalDate.of(2008, 5, 15), "Abcde12!",
                                                "ana@example.com", Perfil.ESTUDANTE, 1, null);

        assertEquals("Ana Silva", pedido.getNome());
        assertEquals(Perfil.ESTUDANTE, pedido.getPerfil());
        assertEquals(1, pedido.getAnoEscolar());
    }

    @Test
    void cadastroProfessorValido() throws Exception {
        PedidoDeCadastro pedido = new PedidoDeCadastro("Ivan Granja",
                                         LocalDate.of(1967, 8, 15), "Ivann12!",
                                         "ana@example.com", Perfil.PROFESSOR, null, "0042");

        assertEquals(Perfil.PROFESSOR, pedido.getPerfil());
        assertEquals("0042", pedido.getCodProfessor());
        assertNull(pedido.getAnoEscolar());
    }

    @Test
    void cadastroEstudanteSemSobrenome() throws Exception {
        // Executa a construção e captura a exceção esperada.
        Exception excecao = assertThrows(
                Exception.class,
                () -> new PedidoDeCadastro("Ana",
                        LocalDate.of(2008, 5, 15), "Abcde12!",
                        "ana@example.com", Perfil.ESTUDANTE, 1, null)
        );

        assertEquals("Informe seu nome e sobrenome.", excecao.getMessage());
    }

    @Test
    void cadastroNomeNulo() throws Exception {
        Exception excecao = assertThrows(
                Exception.class,
                () -> new PedidoDeCadastro(null,
                        LocalDate.of(2008, 5, 15), "Abcde12!",
                        "null@example.com", Perfil.ESTUDANTE, 1, null)
        );

        assertEquals("Informe seu nome e sobrenome.", excecao.getMessage());
    }

    @Test
    void cadastroEmailNulo() throws Exception {
        Exception excecao = assertThrows(
                Exception.class,
                () -> new PedidoDeCadastro("Nulana Alun",
                        LocalDate.of(2008, 5, 15), "Abcde12!",
                        null , Perfil.ESTUDANTE, 1, null)
        );

        assertEquals("Informe um endereco de email valido.", excecao.getMessage());
    }
}
