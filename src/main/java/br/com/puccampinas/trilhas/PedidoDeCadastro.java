package br.com.puccampinas.trilhas;

import java.time.LocalDate;

import static br.com.puccampinas.trilhas.Perfil.ESTUDANTE;
import static br.com.puccampinas.trilhas.Perfil.PROFESSOR;

// Transporta os dados do cadastro; não acessa o banco.
public class PedidoDeCadastro extends Comunicado {
    private final String nome;
    private final LocalDate dataNascimento;
    private final String senha;
    private final String email;
    private final Perfil perfil;
    private final Integer anoEscolar;
    private final String codProfessor;

    public PedidoDeCadastro(String nome, LocalDate dataNascimento, String senha, String email, Perfil perfil,
    Integer anoEscolar, String codProfessor) throws Exception {

        // Normaliza textos sem acessar valores nulos; a senha é preservada.
        if(nome != null) {
            this.nome = nome.strip().replaceAll("\\s+", " ");
        }
        else {
            this.nome = null;
        }

        this.dataNascimento = dataNascimento;
        this.senha = senha;

        if(email != null) {
            this.email = email.strip();
        }
        else {
            this.email = null;
        }

        this.perfil = perfil;
        this.anoEscolar = anoEscolar;
        this.codProfessor = codProfessor;

        // Valida somente após preencher todos os atributos.
        validar();
    }

    // Interrompe na primeira regra inválida, informando sua mensagem.
    public void validar() throws Exception {

        if (nome == null || !nome.strip().matches(
                "[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*(?:\\s+[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*)+"
        )) {
            throw new Exception("Informe seu nome e sobrenome.");
        }

        if (dataNascimento == null || dataNascimento.isBefore(LocalDate.of(1800, 1, 1)) ||
                dataNascimento.isAfter(LocalDate.now())) {
            throw new Exception("Informe uma data de nascimento valida, entre 01/01/1800 e hoje.");
        }

        // Conta dígitos e identifica letras e símbolos na senha.
        int quantidadeDigitos = 0;
        boolean temLetra = false;
        boolean temEspecial = false;

        if (senha != null) {
            for (int i = 0; i < senha.length(); i++) {
                char caractere = senha.charAt(i);

                if (Character.isDigit(caractere)) {
                    quantidadeDigitos++;
                } else if (Character.isLetter(caractere)) {
                    temLetra = true;
                } else if (!Character.isWhitespace(caractere) &&
                        !Character.isSpaceChar(caractere) &&
                        !Character.isISOControl(caractere)) {
                    temEspecial = true;
                }
            }
        }

        if (senha == null || senha.length() < 8 || quantidadeDigitos < 2 ||
                !temLetra || !temEspecial) {
            throw new Exception("A senha deve ter pelo menos 8 caracteres, incluindo uma letra, dois numeros " +
                    "e um caractere especial.");
        }

        if (email == null || !email.strip().matches("[^\\s@]+@[^\\s@.]+(?:\\.[^\\s@.]+)+")) {
            throw new Exception("Informe um endereco de email valido.");
        }

        if (perfil == null) {
            throw new Exception("Perfil invalido.");
        }

        // Exige somente o campo correspondente ao perfil escolhido.
        if (perfil == ESTUDANTE && (anoEscolar == null || anoEscolar < 1 || anoEscolar > 3)) {
            throw new Exception("Selecione o 1º, 2º ou 3º ano.");
        }

        // Aqui verificamos o formato; a existência do código cabe ao Node.js.
        if (perfil == PROFESSOR && (codProfessor == null || !codProfessor.matches("[0-9]{4}"))) {
            throw new Exception("Informe um código de professor com 4 dígitos.");
        }
    }

    public String getNome() { return this.nome; }

    public LocalDate getDataNascimento() { return this.dataNascimento; }

    public String getSenha() { return this.senha; }

    public String getEmail() { return this.email; }

    public Perfil getPerfil() { return this.perfil; }

    public Integer getAnoEscolar() { return this.anoEscolar; }

    public String getCodProfessor() { return this.codProfessor; }
}
