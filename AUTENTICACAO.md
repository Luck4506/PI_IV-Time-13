# Autenticação e reutilização da conta

Cadastro e login usam a mesma conta em `usuarios`, no MongoDB. E-mail normalizado é único, a senha fica protegida com scrypt, e a API confere sessão e perfil. Fazer login novamente mantém o mesmo ID, trilhas, respostas e leituras; não cria outra conta.

No navegador, a sessão agora é restaurada ao atualizar ou reabrir, por até 12 horas após o login. O cookie é HttpOnly e SameSite=Strict. Não salvamos senha ou token no localStorage. A conta é confirmada com a API antes de exibir as telas. Sem sessão, é necessário entrar. Se a conexão falhar, é possível tentar novamente.

As rotas conferem o perfil: estudante não abre a área do professor por URL. A API não permite promover o próprio perfil e filtra trilhas pelo usuário autenticado. Sair revoga as sessões da conta e elimina o cookie. Contas e histórico são preservados. A sessão do aplicativo nativo ainda fica em memória e exige novo login ao reabrir; a restauração persistente implementada aqui é a do navegador.

## Testar

1. Entre com uma conta já cadastrada.
2. Abra Trilha e confira o histórico.
3. Atualize a página: a conta deve permanecer conectada.
4. Na conta de estudante, abra `http://127.0.0.1:5173/#/professor`: aparecerá a restrição de acesso.
5. Volte à sua área, abra Perfil e Sair.
6. Atualize ou abra uma rota privada: deve aparecer o login.
7. Entre com o mesmo e-mail e senha: seu histórico continua lá.

Use 127.0.0.1 tanto no frontend quanto na API durante esses testes. Publicação deve usar HTTPS, COOKIE_SECURE=true e frontend/API no mesmo site.

## Recomendação para verificar o e-mail (ainda não implementada)

Para este projeto, recomendo um **link de confirmação enviado pelo backend através do Resend**, mantendo identidade e progresso no MongoDB. Ele tem SDK oficial para Node.js e exige chave de API e domínio de envio verificado. A chave fica somente no backend.

O fluxo proposto:

1. Criar a conta com e-mail ainda não confirmado e mostrar uma tela pedindo confirmação. Manter os testes atuais liberados enquanto a verificação não for implementada.
2. Gerar um token aleatório forte e exclusivo para verificação. Salvar no Mongo somente o hash, associado ao usuário, e-mail de destino, finalidade, validade e consumo. Minha sugestão de validade inicial é 30 minutos.
3. Enviar um botão **Confirmar meu e-mail** por um domínio próprio verificado no Resend.
4. O link abre uma tela de confirmação. Uma ação explícita envia o token ao backend; o simples carregamento do link não confirma a conta, para não consumir o token em uma prévia automática de e-mail.
5. A API confere finalidade, validade, usuário e e-mail, consome o token uma única vez de forma atômica e registra a confirmação. Um índice de expiração remove tokens antigos, mas a API também verifica o horário, pois essa limpeza não é instantânea.
6. Limitar pedidos de reenvio; invalidar o link anterior ao reenviar. Não registrar tokens ou URLs completas nos logs. Usar respostas discretas para não expor quais endereços estão cadastrados.

Na implementação futura, o campo de confirmação no usuário exigirá atualizar o validador da coleção; não marcar automaticamente as contas existentes como verificadas. A política de liberação das contas já existentes deve ser definida nessa migração. Um token de verificação não deve servir como token de login ou recuperação de senha.

Confirmar o e-mail demonstra acesso à caixa de entrada. A autorização de professor e o vínculo com a escola precisam de uma regra própria. Recuperação de senha e login Google também continuam pendentes.

Fontes: [Resend para Node.js](https://resend.com/docs/send-with-nodejs), [verificação de e-mail da OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Email_Validation_and_Verification_Cheat_Sheet.html) e [gerenciamento de sessão da OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html). O prazo de 30 minutos e o desenho de integração são recomendações para este projeto.
