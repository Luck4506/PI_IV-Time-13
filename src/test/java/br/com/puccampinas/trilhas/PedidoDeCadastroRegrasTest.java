package br.com.puccampinas.trilhas;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.time.LocalDate;

// Complementa PedidoDeCadastroTest: limites de data, ano escolar, código do professor e senha.
// Em cada cenário de rejeição, só o campo testado é inválido; os demais seguem válidos.
public class PedidoDeCadastroRegrasTest {

    private static final String MSG_DATA =
            "Informe uma data de nascimento valida, entre 01/01/1800 e 01/01/3000.";
    private static final String MSG_SENHA =
            "A senha deve ter pelo menos 8 caracteres, incluindo uma letra, dois numeros e um caractere especial.";
    private static final String MSG_ANO = "Selecione Outro ou um ano do Ensino Medio valido.";
    private static final String MSG_CODIGO = "Informe um codigo de professor com 4 digitos.";

    // Cria um estudante válido trocando apenas a data.
    private PedidoDeCadastro estudanteComData(LocalDate data) throws Exception {
        return new PedidoDeCadastro("Ana Silva", data, "Abcde12!",
                "ana@example.com", Perfil.ESTUDANTE, 1, null, false, null, true, null);
    }

    // Cria um estudante válido trocando apenas a senha.
    private PedidoDeCadastro estudanteComSenha(String senha) throws Exception {
        return new PedidoDeCadastro("Ana Silva", LocalDate.of(2008, 5, 15), senha,
                "ana@example.com", Perfil.ESTUDANTE, 1, null, false, null, true, null);
    }

    // Cria um estudante válido trocando apenas o ano escolar.
    private PedidoDeCadastro estudanteComAno(Integer ano) throws Exception {
        return new PedidoDeCadastro("Ana Silva", LocalDate.of(2008, 5, 15), "Abcde12!",
                "ana@example.com", Perfil.ESTUDANTE, ano, null, false, null, true, null);
    }

    // Cria um professor válido trocando apenas o código.
    private PedidoDeCadastro professorComCodigo(String codigo) throws Exception {
        return new PedidoDeCadastro("Ivan Granja", LocalDate.of(1967, 8, 15), "Abcde12!",
                "ivan@example.com", Perfil.PROFESSOR, null, codigo, true, "ESCOLA-DEMO-001", true, null);
    }

    // Confere que a criação falha com exatamente a mensagem esperada.
    private void esperaRecusaDaSenha(String senha) {
        Exception excecao = assertThrows(Exception.class, () -> estudanteComSenha(senha));
        assertEquals(MSG_SENHA, excecao.getMessage());
    }

    // ---------- Data de nascimento ----------

    @Test
    void nascimentoNoLimiteMinimoEhValido() throws Exception {
        // O limite inferior faz parte do intervalo permitido.
        PedidoDeCadastro pedido = estudanteComData(LocalDate.of(1800, 1, 1));

        assertEquals(LocalDate.of(1800, 1, 1), pedido.getDataNascimento());
    }

    @Test
    void nascimentoUmDiaAntesDoMinimoEhRecusado() {
        // Um dia antes do limite já deve ser rejeitado.
        Exception excecao = assertThrows(Exception.class,
                () -> estudanteComData(LocalDate.of(1799, 12, 31)));

        assertEquals(MSG_DATA, excecao.getMessage());
    }

    @Test
    void nascimentoNoLimiteMaximoEhValido() throws Exception {
        // O schema permite datas futuras até 01/01/3000, inclusive.
        LocalDate data = LocalDate.of(3000, 1, 1);

        PedidoDeCadastro pedido = estudanteComData(data);

        assertEquals(data, pedido.getDataNascimento());
    }

    @Test
    void nascimentoUmDiaDepoisDoMaximoEhRecusado() {
        // Um dia após o limite superior já está fora do intervalo permitido.
        Exception excecao = assertThrows(Exception.class,
                () -> estudanteComData(LocalDate.of(3000, 1, 2)));

        assertEquals(MSG_DATA, excecao.getMessage());
    }

    @Test
    void nascimentoNuloEhRecusado() {
        // Data de nascimento é obrigatória.
        Exception excecao = assertThrows(Exception.class, () -> estudanteComData(null));

        assertEquals(MSG_DATA, excecao.getMessage());
    }

    // ---------- Ano escolar (estudante) ----------

    @Test
    void anoEscolarTresEhValido() throws Exception {
        // O terceiro ano é o maior ano escolar aceito.
        assertEquals(3, estudanteComAno(3).getAnoEscolar());
    }

    @Test
    void anoEscolarDoisEhValido() throws Exception {
        // Um valor intermediário do Ensino Médio deve ser preservado.
        assertEquals(2, estudanteComAno(2).getAnoEscolar());
    }

    @Test
    void estudanteSemAnoEscolarEhRecusado() {
        // O aluno precisa informar o ano escolar, inclusive quando escolhe Outro.
        Exception excecao = assertThrows(Exception.class, () -> estudanteComAno(null));

        assertEquals(MSG_ANO, excecao.getMessage());
    }

    @Test
    void anoEscolarZeroEhValido() throws Exception {
        // Zero representa Outro no schema atual, sem vínculo com um ano específico.
        assertEquals(0, estudanteComAno(0).getAnoEscolar());
    }

    @Test
    void anoEscolarNegativoEhRecusado() {
        // O primeiro valor abaixo do intervalo 0..3 deve ser rejeitado.
        Exception excecao = assertThrows(Exception.class, () -> estudanteComAno(-1));

        assertEquals(MSG_ANO, excecao.getMessage());
    }

    @Test
    void anoEscolarQuatroEhRecusado() {
        // O valor imediatamente acima de 3 não representa uma opção válida.
        Exception excecao = assertThrows(Exception.class, () -> estudanteComAno(4));

        assertEquals(MSG_ANO, excecao.getMessage());
    }

    // ---------- Código do professor ----------

    @Test
    void professorSemCodigoEhRecusado() {
        // O código do professor é obrigatório.
        Exception excecao = assertThrows(Exception.class, () -> professorComCodigo(null));

        assertEquals(MSG_CODIGO, excecao.getMessage());
    }

    @Test
    void codigoComLetrasEhRecusado() {
        // Quatro caracteres não bastam: todos precisam ser dígitos ASCII.
        Exception excecao = assertThrows(Exception.class, () -> professorComCodigo("00A2"));

        assertEquals(MSG_CODIGO, excecao.getMessage());
    }

    @Test
    void codigoComTresDigitosEhRecusado() {
        // Código abaixo do tamanho exigido deve ser rejeitado.
        Exception excecao = assertThrows(Exception.class, () -> professorComCodigo("042"));

        assertEquals(MSG_CODIGO, excecao.getMessage());
    }

    @Test
    void codigoComCincoDigitosEhRecusado() {
        // Código acima do tamanho exigido deve ser rejeitado.
        Exception excecao = assertThrows(Exception.class, () -> professorComCodigo("00420"));

        assertEquals(MSG_CODIGO, excecao.getMessage());
    }

    @Test
    void codigoComDigitosNaoAsciiEhRecusado() {
        // Dígitos arábico-indicos "0042": são dígitos Unicode, mas o contrato exige ASCII.
        Exception excecao = assertThrows(Exception.class,
                () -> professorComCodigo("٠٠٤٢"));

        assertEquals(MSG_CODIGO, excecao.getMessage());
    }

    // ---------- Senha: um requisito por teste ----------

    @Test
    void senhaComOitoCaracteresEhValida() throws Exception {
        // "Abcde12!" tem exatamente 8 caracteres e cumpre os demais requisitos.
        assertEquals("Abcde12!", estudanteComSenha("Abcde12!").getSenha());
    }

    @Test
    void senhaComSeteCaracteresEhRecusada() {
        // Só o tamanho falha: tem letra, dois dígitos e especial.
        esperaRecusaDaSenha("Abcd12!");
    }

    @Test
    void senhaSemLetraEhRecusada() {
        // Só a letra falta: 8 caracteres, vários dígitos e especial.
        esperaRecusaDaSenha("1234567!");
    }

    @Test
    void senhaComApenasUmDigitoEhRecusada() {
        // Só os dígitos falham: 8 caracteres, letra, um dígito e especial.
        esperaRecusaDaSenha("Abcdef1!");
    }

    @Test
    void senhaSemCaractereEspecialEhRecusada() {
        // Só o especial falta: 8 caracteres, letra e dois dígitos.
        esperaRecusaDaSenha("Abcdef12");
    }

    @Test
    void espacoNaoContaComoCaractereEspecial() {
        // Oito caracteres, letra, dois dígitos; o único "símbolo" é um espaço.
        esperaRecusaDaSenha("Abcde12 ");
    }

    @Test
    void tabulacaoNaoContaComoCaractereEspecial() {
        // Tabulação não satisfaz a exigência de um caractere especial.
        esperaRecusaDaSenha("Abcde12\t");
    }

    @Test
    void caractereDeControleNaoContaComoCaractereEspecial() {
        // \u0001 é um caractere de controle ASCII.
        esperaRecusaDaSenha("Abcde12\u0001");
    }

    @Test
    void senhaNulaEhRecusada() {
        // Uma senha ausente não pode criar um cadastro válido.
        esperaRecusaDaSenha(null);
    }
}
