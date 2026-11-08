package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

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
        Exception excecao = assertThrows(
                Exception.class,
                () -> new PedidoDeCadastro("Ana",
                        LocalDate.of(2008, 5, 15), "Abcde12!",
                        "ana@example.com", Perfil.ESTUDANTE, 1, null)
        );

        assertEquals("Informe seu nome e sobrenome.", excecao.getMessage());
    }
}
