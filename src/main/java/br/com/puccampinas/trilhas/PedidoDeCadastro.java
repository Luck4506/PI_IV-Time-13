// Autoria de Henrique RA 25005651 e Arthur Valerio De Santi RA 25006924

package br.com.puccampinas.trilhas;

import static br.com.puccampinas.trilhas.Perfil.ESTUDANTE;
import static br.com.puccampinas.trilhas.Perfil.PROFESSOR;
import java.time.LocalDate;
import java.util.Locale;

// Transporta os dados do cadastro; não acessa o banco.
public class PedidoDeCadastro extends Comunicado {
    private final String nome;
    private final String senha;
    private final String email;
    private final Perfil perfil;
    private final LocalDate dataNascimento;
    private final Integer anoEscolar;
    private final String codProfessor;
    private final Boolean cadastroEducacional;
    private final String codigoEscola;
    private final Boolean termosAceitos;
    private final String codigoTurma;

    public PedidoDeCadastro(String nome, LocalDate dataNascimento, String senha, String email,
                            Perfil perfil, Integer anoEscolar, String codProfessor, Boolean cadastroEducacional,
                            String codigoEscola, Boolean termosAceitos, String codigoTurma)
    throws Exception {


        // Remove espaços das extremidades e também reduz espaços internos repetidos.
        if(nome != null) {
            this.nome = nome.strip().replaceAll("\\s+", " ");
        }
        else {
            this.nome = null;
        }

        this.senha = senha;

        if(email != null) {
            this.email = email.strip();
        }
        else {
            this.email = null;
        }

        // Campo omitido: professor é educacional; aluno assume cadastro sem vínculo.
        if(cadastroEducacional == null) {
            this.cadastroEducacional = (perfil == PROFESSOR);
        }
        else {
            this.cadastroEducacional = cadastroEducacional;
        }

        // Normaliza códigos presentes sem transformar ausência em texto vazio.
        if(codigoEscola != null) {
            this.codigoEscola = codigoEscola.strip();
        }
        else {
            this.codigoEscola = null;
        }

        if(codigoTurma != null) {
            this.codigoTurma = codigoTurma.strip().toUpperCase(Locale.ROOT); // independe do idioma do computador.
        }
        else {
            this.codigoTurma = null;
        }

        this.perfil = perfil;
        this.anoEscolar = anoEscolar;
        this.dataNascimento = dataNascimento;
        this.codProfessor = codProfessor;
        this.termosAceitos = termosAceitos;

        // Valida somente após preencher todos os atributos.
        validar();
    }

    // Interrompe na primeira regra inválida, informando sua mensagem.
    public void validar() throws Exception {

        // Exige nome e sobrenome, aceitando acentos, hífen e apóstrofo.
        if (nome == null || !nome.strip().matches(
                "[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*(?:\\s+[\\p{L}\\p{M}]+(?:['’\\-][\\p{L}\\p{M}]+)*)+"
        )) {
            throw new Exception("Informe seu nome e sobrenome.");
        }

        // Confere a composição da senha sem modificar o texto recebido.
        int countDigitos = 0;
        boolean encontrouLetra = false;
        boolean encontrouEspecial = false;

        if (senha != null) {
            for(int i = 0; i < senha.length(); i++) {
                char caractere = senha.charAt(i);

                if(Character.isDigit(caractere)) {
                    countDigitos++;
                }
                else if(Character.isLetter(caractere)) {
                    encontrouLetra = true;
                }
                else if(!Character.isWhitespace(caractere) &&
                   !Character.isSpaceChar(caractere) &&
                   !Character.isISOControl(caractere)
                ) {
                    encontrouEspecial = true;
                }
            }
        }

        if(senha == null || senha.length() < 8 || countDigitos < 2 ||
           encontrouLetra == false || encontrouEspecial == false) {
            throw new Exception("A senha deve ter pelo menos 8 caracteres," +
                    " incluindo uma letra, dois numeros e um caractere especial.");
        }

        if (email == null || !email.strip().matches("[^\\s@]+@[^\\s@.]+(?:\\.[^\\s@.]+)+")) {
            throw new Exception("Informe um endereco de email valido.");
        }

        if (perfil == null) {
            throw new Exception("Perfil invalido.");
        }

        // Verifica o vínculo e os formatos; existência de escola/turma cabe ao Node.js.
        if (perfil == PROFESSOR && cadastroEducacional == false) {
            throw new Exception("Professor deve possuir cadastro educacional.");
        }

        if (cadastroEducacional == true && codigoEscola == null) {
            throw new Exception("Selecione sua escola.");
        }

        if (codigoEscola != null && (codigoEscola.length() < 1 || codigoEscola.length() > 80)) {
            throw new Exception("Codigo da escola deve ter entre 1 e 80 caracteres.");
        }

        if (cadastroEducacional == false && (codigoEscola != null || codigoTurma != null)) {
            throw new Exception("Cadastro sem vinculo educacional nao permite escola ou turma.");
        }

        if (codigoTurma != null) {
            if(perfil != ESTUDANTE || !cadastroEducacional) {
                throw new Exception("Codigo de turma permitido apenas para aluno com cadastro educacional.");
            }
            if(!codigoTurma.matches("[0-9A-F]{12}")) {
                throw new Exception("Codigo da turma deve conter 12 caracteres hexadecimais.");
            }
        }

        // Somente true confirma aceite; false e ausência são rejeitados com segurança.
        if (!Boolean.TRUE.equals(termosAceitos)) {
            throw new Exception("E necessario aceitar os termos de uso.");
        }

        // Para aluno, 0 representa Outro e 1–3 representam os anos do Ensino Médio.
        if (perfil == ESTUDANTE && (anoEscolar == null || anoEscolar < 0 || anoEscolar > 3)) {
            throw new Exception("Selecione Outro ou um ano do Ensino Medio valido.");
        }

        // O contrato permite datas futuras até 01/01/3000, inclusive.
        if (dataNascimento == null)
            throw new Exception("Informe uma data de nascimento valida, entre 01/01/1800 e 01/01/3000.");

        if (dataNascimento.isBefore(LocalDate.of(1800, 1, 1)) || dataNascimento.isAfter(LocalDate.of(3000, 1, 1))) {
            throw new Exception("Informe uma data de nascimento valida, entre 01/01/1800 e 01/01/3000.");
        }

        if(perfil == PROFESSOR) {
            if(codProfessor == null || !codProfessor.matches("[0-9]{4}")) {
                throw new Exception("Informe um codigo de professor com 4 digitos.");
            }
        }

    }

    public String getNome() { return this.nome; }

    public String getSenha() { return this.senha; }

    public String getEmail() { return this.email; }

    public Perfil getPerfil() { return this.perfil; }

    public Integer getAnoEscolar() { return this.anoEscolar; }

    public LocalDate getDataNascimento() { return this.dataNascimento; }

    public String getCodProfessor() { return this.codProfessor; }

    public Boolean isCadastroEducacional() { return this.cadastroEducacional; }

    public String getCodigoEscola() { return this.codigoEscola; }

    public Boolean isTermosAceitos() { return this.termosAceitos; }

    public String getCodigoTurma() { return this.codigoTurma; }
}
