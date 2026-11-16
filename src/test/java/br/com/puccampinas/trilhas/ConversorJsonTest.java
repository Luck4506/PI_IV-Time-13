package br.com.puccampinas.trilhas;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.time.LocalDate;
import com.google.gson.JsonNull;

public class ConversorJsonTest {

    @Test
    void jsonValido() throws Exception {
        ResultadoValidacao resultado = new ResultadoValidacao(true, "Campos validos.");
        // JSON em forma de texto (String): é o que será enviado pelo socket.
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

        // toString() produz o texto JSON; o conversor retorna um pedido Java.
        PedidoDeCadastro retorno = new ConversorJson().converterPedido(json.toString());

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
        String jsonLista = "[]";
        Exception excecao = assertThrows(
            Exception.class,
            () -> new ConversorJson().converterPedido(jsonLista)
        );

        assertEquals("O pedido deve ser um objeto JSON.", excecao.getMessage());
    }

    @Test
    void rejeitarJsonMalformado() throws Exception {
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

        // toString() produz o texto JSON; o conversor retorna um pedido Java.
        PedidoDeCadastro retorno = new ConversorJson().converterPedido(json.toString());

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
}
