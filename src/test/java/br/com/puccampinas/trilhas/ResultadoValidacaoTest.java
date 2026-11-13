package br.com.puccampinas.trilhas;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class ResultadoValidacaoTest {

    @Test
    void aprovacao() throws Exception {
        ResultadoValidacao resultado = new ResultadoValidacao(true, "Campos validos.");

        assertTrue(resultado.isValido());
        assertEquals("Campos validos.", resultado.getMensagem());
    }

    @Test
    void rejeicao() throws Exception {
        ResultadoValidacao resultado = new ResultadoValidacao(false, "Aparicao de campo invalido.");

        assertFalse(resultado.isValido());
        assertEquals("Aparicao de campo invalido.", resultado.getMensagem());
    }

}
