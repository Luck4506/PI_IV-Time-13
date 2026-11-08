package br.com.puccampinas.trilhas;

import java.time.LocalDate;

import static br.com.puccampinas.trilhas.Perfil.ESTUDANTE;
import static br.com.puccampinas.trilhas.Perfil.PROFESSOR;

public class PedidoDeCadastro extends Comunicado {
    private final String nome;
    private final LocalDate dataNascimento;
    private final String senha;
    private final String email;
    private final Perfil perfil;
    private final Integer anoEscolar;
    private final String codProfessor;

    public PedidoDeCadastro(String nome, LocalDate dn, String senha, String email, Perfil perfil,
    Integer anoEscolar, String codProf) throws Exception {

        if(nome == null || !nome.strip().matches(
                "[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*(?:\\s+[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*)+"
        )) {
            throw new Exception("Informe seu nome e sobrenome.");
        }

        if(dn == null || dn.isBefore(LocalDate.of(1800, 1, 1)) ||
           dn.isAfter(LocalDate.now())) {
            throw new Exception("Informe uma data de nascimento válida, entre 01/01/1800 e hoje.");
        }

        int quantidadeDigitos = 0;
        boolean temLetra = false;
        boolean temEspecial = false;

        if(senha != null) {
            for(int i = 0; i < senha.length(); i++) {
                char caractere = senha.charAt(i);

                if(Character.isDigit(caractere)) {
                    quantidadeDigitos++;
                }
                else if(Character.isLetter(caractere)) {
                    temLetra = true;
                }
                else if(!Character.isWhitespace(caractere) &&
                        !Character.isSpaceChar(caractere) &&
                        !Character.isISOControl(caractere)) {
                    temEspecial = true;
                }
            }
        }

        if(senha == null || senha.length() < 8 || quantidadeDigitos < 2 ||
           !temLetra || !temEspecial) {
            throw new Exception("A senha deve ter pelo menos 8 caracteres, incluindo uma letra, dois números " +
                    "e um caractere especial.");
        }

        if(email == null || !email.strip().matches("[^\\s@]+@[^\\s@.]+(?:\\.[^\\s@.]+)+")) {
            throw new Exception("Informe um endereço de email válido.");
        }

        if(perfil == null) {
            throw new Exception("Perfil inválido.");
        }

        if(perfil == ESTUDANTE && (anoEscolar == null || anoEscolar < 1 || anoEscolar > 3)) {
            throw new Exception("Selecione o 1º, 2º ou 3º ano.");
        }
            
        if(perfil == PROFESSOR && (codProf == null || !codProf.matches("[0-9]{4}"))) {
            throw new Exception("Informe um código de professor com 4 dígitos.");
        }

        this.nome = nome.strip().replaceAll("\\s+", " ");
        this.dataNascimento = dn;
        this.senha = senha;
        this.email = email.strip();
        this.perfil = perfil;
        this.anoEscolar = anoEscolar;
        this.codProfessor = codProf;
    }

    public String getNome() { return this.nome; }

    public LocalDate getDataNascimento() { return this.dataNascimento; }

    public String getSenha() { return this.senha; }

    public String getEmail() { return this.email; }

    public Perfil getPerfil() { return this.perfil; }

    public Integer getAnoEscolar() { return this.anoEscolar; }

    public String getCodProfessor() { return this.codProfessor; }
}
