// Autoria de Sofia de Sousa RA 25005435 e Henrique Young 25005651

package br.com.puccampinas.trilhas;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

// Verifica leitura dos pedidos, tipos JSON e rejeições antes do encaminhamento ao Node.
public class ConversorJsonTest {

    @Test
    void jsonValido() throws Exception {
        ResultadoValidacao resultado = new ResultadoValidacao(true, "Campos validos.");
        // Testa o formato de validação isoladamente; a supervisora usa a resposta final da operação.
        String texto = new ConversorJson().converterResultado(resultado);
        // O mesmo JSON interpretado pelo Gson: permite consultar seus campos.
        JsonObject json = JsonParser.parseString(texto).getAsJsonObject();

        // Extrai os valores de cada campo para compará-los no teste.
        assertTrue(json.get("valido").getAsBoolean());
        assertEquals("Campos validos.", json.get("mensagem").getAsString());
    }

    @Test
    void converterCadastroEstudanteValido() throws Exception {
        // Simula um pedido de cadastro enviado pelo Flutter ao Java.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        // Confere se o pedido e de cadastro antes de acessar seus campos.
        assertInstanceOf(PedidoDeCadastro.class, comunicado);
        PedidoDeCadastro retorno = (PedidoDeCadastro) comunicado;

        // Confere também a conversão de texto para data e perfil.
        assertEquals("Ana Silva", retorno.getNome());
        assertEquals(LocalDate.of(2008, 5, 15), retorno.getDataNascimento());
        assertEquals(Perfil.ESTUDANTE, retorno.getPerfil());
        assertEquals(1, retorno.getAnoEscolar());
    }

    @Test
    void converterCadastroComDataImpossivel() throws Exception {
        // Somente a data é inválida, para isolar o motivo da rejeição.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-02-30");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe uma data de nascimento valida, entre 01/01/1800 e 01/01/3000.",
                     excecao.getMessage());
    }

    @Test
    void rejeitarAnoEscolarFracionario() throws Exception {
        // Confere que 1.5 é rejeitado, em vez de ser convertido para 1.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1.5);
        json.addProperty("termosAceitos", true);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );
    }

    @Test
    void rejeitarCodigoProfessorNumerico() throws Exception {
        // O código deve chegar como texto, preservando possíveis zeros iniciais.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ivan Granja");
        json.addProperty("dataNascimento", "1967-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ivan@example.com");
        json.addProperty("perfil", 2);
        json.addProperty("codProfessor", 1234);
        json.addProperty("termosAceitos", true);
        json.addProperty("codigoEscola", "ESCOLA-DEMO-001");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo codProfessor deve ser informado como texto.", excecao.getMessage());
    }

    @Test
    void rejeitarSenhaNumerica() throws Exception {
        // Somente o tipo da senha está incorreto; os demais campos são válidos.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", 12345678);
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo senha deve ser informado como texto.", excecao.getMessage());
    }

    @Test
    void rejeitarJsonQueNaoSejaObjeto() throws Exception {
        // JSON válido também pode ser uma lista; o protocolo exige um objeto.
        String jsonLista = "[]";
        Exception excecao = assertThrows(
            Exception.class,
            () -> new ConversorJson().converterPedido(jsonLista)
        );

        assertEquals("O pedido deve ser um objeto JSON.", excecao.getMessage());
    }

    @Test
    void rejeitarJsonMalformado() throws Exception {
        // Sintaxe incompleta deve receber uma mensagem própria de JSON inválido.
        String jsonMalformado = "{";
        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(jsonMalformado)
        );

        assertEquals("JSON invalido.", excecao.getMessage());
    }

    @Test
    void converterCadastroEducacionalComTurma() throws Exception {
        // Simula um aluno com vínculo escolar e código de turma informado pelo Flutter.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);
        json.addProperty("cadastroEducacional", true);
        json.addProperty("codigoEscola", " ESCOLA-DEMO-001 ");
        json.addProperty("codigoTurma", " 0a1b2c3d4e5f ");

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        // Confere se o pedido e de cadastro antes de acessar seus campos.
        assertInstanceOf(PedidoDeCadastro.class, comunicado);
        PedidoDeCadastro retorno = (PedidoDeCadastro) comunicado;

        // Confere também a conversão de texto para data e perfil.
        assertEquals("Ana Silva", retorno.getNome());
        assertEquals(LocalDate.of(2008, 5, 15), retorno.getDataNascimento());
        assertEquals(Perfil.ESTUDANTE, retorno.getPerfil());
        assertEquals(1, retorno.getAnoEscolar());
        // Confere o vínculo e a normalização de espaços e letras do código da turma.
        assertTrue(retorno.isCadastroEducacional());
        assertEquals("ESCOLA-DEMO-001", retorno.getCodigoEscola());
        assertEquals("0A1B2C3D4E5F", retorno.getCodigoTurma());
    }

    @Test
    void rejeitarCadastroEducacionalTextual() throws Exception {
        // Texto "true" não pode ser convertido automaticamente em booleano.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);
        json.addProperty("cadastroEducacional", "true");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo cadastroEducacional deve ser informado como booleano.", excecao.getMessage());
    }

    @Test
    void rejeitarCadastroEducacionalNulo() throws Exception {
        // JSON null explícito é inválido; campo omitido permite o padrão do perfil.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", 1);
        json.addProperty("anoEscolar", 1);
        json.addProperty("termosAceitos", true);
        json.add("cadastroEducacional", JsonNull.INSTANCE);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo cadastroEducacional deve ser informado como booleano.", excecao.getMessage());
    }

    @Test
    void converterLoginValido() throws Exception {
        // Reconhece o login e preserva os campos no PedidoDeLogin retornado.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "Abcde12!");

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        // Confere a operação identificada e os campos do pedido.
        assertInstanceOf(PedidoDeLogin.class, comunicado);
        PedidoDeLogin retorno = (PedidoDeLogin) comunicado;

        assertEquals("ana@example.com", retorno.getEmail());
        assertEquals("Abcde12!", retorno.getSenha());
    }

    @Test
    void converterLoginAceitaSenhaQueNaoSegueRegraDeCadastro() throws Exception {
        // Login exige senha preenchida; a regra de força é aplicada somente no cadastro.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "abc");

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        // A conferência da senha com o valor salvo fica com o Node.
        assertInstanceOf(PedidoDeLogin.class, comunicado);
        PedidoDeLogin retorno = (PedidoDeLogin) comunicado;

        assertEquals("abc", retorno.getSenha());
    }

    @Test
    void rejeitarLoginSemSenha() throws Exception {
        // Campo senha omitido impede a criação do pedido.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe sua senha.", excecao.getMessage());
    }

    @Test
    void rejeitarLoginComSenhaNumerica() throws Exception {
        // Rejeita número sem convertê-lo automaticamente em uma senha textual.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", 12345678);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals(
                "Campo senha deve ser informado como texto.",
                excecao.getMessage()
        );
    }

    @Test
    void rejeitarLoginComEmailInvalido() throws Exception {
        // Mesmo sendo texto, o e-mail precisa ter um formato válido.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana.example.com");
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe um endereço de email válido.", excecao.getMessage());
    }

    @Test
    void rejeitarLoginSemEmail() throws Exception {
        // O e-mail é obrigatório para identificar a conta no login.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe um endereço de email válido.", excecao.getMessage());
    }

    @Test
    void rejeitarLoginComEmailNumerico() throws Exception {
        // Rejeita o tipo numérico antes de conferir o formato do e-mail.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", 123);
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals(
                "Campo email deve ser informado como texto.",
                excecao.getMessage()
        );
    }

    @Test
    void rejeitarLoginComSenhaNula() throws Exception {
        // JSON null recebe a mesma rejeição de uma senha não enviada.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.add("senha", JsonNull.INSTANCE);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe sua senha.", excecao.getMessage());
    }

    @Test
    void rejeitarLoginComSenhaVazia() throws Exception {
        // Texto vazio não atende à exigência de senha preenchida.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe sua senha.", excecao.getMessage());
    }

    @Test
    void rejeitarTipoDesconhecido() throws Exception {
        // Somente as operações reconhecidas podem gerar um pedido.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "APAGAR_TUDO");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Tipo de pedido nao suportado. Esperado: VALIDAR_CADASTRO ou VALIDAR_LOGIN.",
                     excecao.getMessage());
    }

    @Test
    void rejeitarPedidoSemTipo() throws Exception {
        // Sem tipo, o conversor não pode escolher entre cadastro e login.
        JsonObject json = new JsonObject();
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Tipo de pedido invalido.", excecao.getMessage());
    }

    @Test
    void rejeitarTipoNumerico() throws Exception {
        // O identificador da operação deve ser texto, nunca um número.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", 1);
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo tipo deve ser informado como texto.", excecao.getMessage());
    }
}
