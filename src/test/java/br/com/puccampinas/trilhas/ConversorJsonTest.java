package br.com.puccampinas.trilhas;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;
import com.google.gson.JsonNull;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.time.LocalDate;

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
        // Monta um pedido de exemplo com os campos enviados pelo Node.js.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", "Abcde12!");
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", "student");
        json.addProperty("anoEscolar", 1);

        // toString() produz o texto JSON; o conversor retorna um Comunicado.
        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        // Confere o tipo retornado antes de converter para acessar os getters do cadastro.
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
        json.addProperty("perfil", "student");
        json.addProperty("anoEscolar", 1);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Informe uma data de nascimento valida, entre 01/01/1800 e hoje.", excecao.getMessage());
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
        json.addProperty("perfil", "student");
        json.addProperty("anoEscolar", 1.5);

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
        json.addProperty("perfil", "teacher");
        json.addProperty("codProfessor", 1234);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo codProfessor deve ser informado como texto.", excecao.getMessage());
    }

    @Test
    void rejeitarSenhaNumerica() throws Exception {
        // Monta um pedido de exemplo com os campos enviados pelo Node.js.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_CADASTRO");
        json.addProperty("nome", "Ana Silva");
        json.addProperty("dataNascimento", "2008-05-15");
        json.addProperty("senha", 12345678);
        json.addProperty("email", "ana@example.com");
        json.addProperty("perfil", "student");
        json.addProperty("anoEscolar", 1);

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
    void converterLoginValido() throws Exception {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "Abcde12!");

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        assertInstanceOf(PedidoDeLogin.class, comunicado);
        PedidoDeLogin retorno = (PedidoDeLogin) comunicado;

        assertEquals("ana@example.com", retorno.getEmail());
        assertEquals("Abcde12!", retorno.getSenha());
    }

    @Test
    void converterLoginAceitaSenhaQueNaoSegueRegraDeCadastro() throws Exception {
        // No login a força da senha não é avaliada: quem confere a senha é o Node.js.
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", "abc");

        Comunicado comunicado = new ConversorJson().converterPedido(json.toString());

        assertInstanceOf(PedidoDeLogin.class, comunicado);
        assertEquals("abc", ((PedidoDeLogin) comunicado).getSenha());
    }

    @Test
    void rejeitarLoginSemEmail() throws Exception {
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
    void rejeitarLoginSemSenha() throws Exception {
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
    void rejeitarLoginComSenhaNula() throws Exception {
        // JSON null é tratado como ausência, igual ao campo omitido.
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
    void rejeitarLoginComEmailInvalido() throws Exception {
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
    void rejeitarLoginComEmailNumerico() throws Exception {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", 123);
        json.addProperty("senha", "Abcde12!");

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo email deve ser informado como texto.", excecao.getMessage());
    }

    @Test
    void rejeitarLoginComSenhaNumerica() throws Exception {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "VALIDAR_LOGIN");
        json.addProperty("email", "ana@example.com");
        json.addProperty("senha", 12345678);

        Exception excecao = assertThrows(
                Exception.class,
                () -> new ConversorJson().converterPedido(json.toString())
        );

        assertEquals("Campo senha deve ser informado como texto.", excecao.getMessage());
    }


    @Test
    void rejeitarTipoDesconhecido() throws Exception {
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