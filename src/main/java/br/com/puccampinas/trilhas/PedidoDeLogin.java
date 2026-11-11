package br.com.puccampinas.trilhas;

public class PedidoDeLogin extends Comunicado {
    private final String email;
    private final String senha;

    public PedidoDeLogin(String email, String senha) throws Exception {

        // parte de validação reaproveitada do PedidoDeCadastro
        if(email == null || !email.strip().matches("[^\\s@]+@[^\\s@.]+(?:\\.[^\\s@.]+)+")) {
            throw new Exception("Informe um endereço de email válido.");
        }

        // A senha eu não preciso validar a regra dela, apenas confirmar se vai bater com a do banco
        if(senha == null || senha.isEmpty()) {
            throw new Exception("Informe sua senha.");
        }

        // Strip - remove os espaços em branco do início e do fim do texto
        this.email = email.strip();
        this.senha = senha;
    }

    public String getEmail() { return this.email; }

    public String getSenha() { return this.senha; }
}