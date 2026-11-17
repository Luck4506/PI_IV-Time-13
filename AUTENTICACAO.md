# Conta e confirmação de e-mail

O app usa o mesmo e-mail para entrar novamente e recuperar o histórico da conta. O Node confere a senha protegida com scrypt no MongoDB e emite um token com validade de 12 horas. O Flutter guarda o token em memória e o envia nas rotas privadas. Ao fechar e reabrir o app, faça login novamente. Sair revoga os tokens da conta e preserva o histórico.

## Confirmação da conta

Quando a confirmação está ativa, o cadastro envia um código por e-mail. No aplicativo, informe o código e a senha do cadastro. O código vale por 30 minutos e pode ser usado uma vez. Após um minuto, é possível pedir outro código. O reenvio invalida o anterior.

As contas existentes de antes da ativação continuam acessíveis. No MongoDB, a coleção `verificacoes_email` guarda o estado da confirmação e o hash do código.

## Configurar o remetente

Preencha `EMAIL_VERIFICATION_REQUIRED=true`, `SMTP_HOST`, `SMTP_PORT` e `SMTP_FROM` no arquivo `backend/.env`. Use um remetente autorizado pelo provedor. Se o provedor exigir autenticação, preencha também `SMTP_USER` e `SMTP_PASSWORD`. Reinicie a API para aplicar a configuração. [Modelo público do ambiente](backend/.env.example)

Sem remetente, a API informa a indisponibilidade antes de criar a conta. Se o envio falhar depois de gravar a conta, ela fica pendente e a tela oferece o reenvio. Em desenvolvimento local, `EMAIL_VERIFICATION_REQUIRED=false` permite novos cadastros sem envio. Com `NODE_ENV=production`, a confirmação é obrigatória.

O backend permite cadastro de professor por padrão. Ajuste `ALLOW_TEACHER_REGISTRATION` no ambiente se precisar desativá-lo. A escola é informada no cadastro, e o professor entra em uma turma existente por convite.
