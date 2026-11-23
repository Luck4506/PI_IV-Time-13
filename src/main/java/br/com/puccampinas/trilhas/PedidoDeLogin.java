// Autoria de Sofia de Sousa RA 25005435

package br.com.puccampinas.trilhas;

public class PedidoDeLogin extends Comunicado {
    private final String email;
    private final String senha;

    public PedidoDeLogin(String email, String senha) throws Exception {

        // Aplica a mesma regra de formato de e-mail usada no cadastro.
        if(email == null || !email.strip().matches("[^\\s@]+@[^\\s@.]+(?:\\.[^\\s@.]+)+")) {
            throw new Exception("Informe um endereço de email válido.");
        }

        // Exige senha preenchida e preserva seu conteúdo; o Node confere as credenciais.
        if(senha == null || senha.isEmpty()) {
            throw new Exception("Informe sua senha.");
        }

        // Remove espaços das extremidades do e-mail, sem modificar a senha.
        this.email = email.strip();
        this.senha = senha;
    }

    public String getEmail() { return this.email; }

    public String getSenha() { return this.senha; }
}
