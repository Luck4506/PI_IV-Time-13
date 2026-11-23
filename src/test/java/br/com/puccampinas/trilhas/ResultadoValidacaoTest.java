// Autoria de Henrique RA 25005651

package br.com.puccampinas.trilhas;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

// Confere o resultado de validação isolado, sem representar uma operação concluída no Node.
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
