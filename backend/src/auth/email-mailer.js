// Autoria de Lucas Soares Gonçalves RA 25009467
import nodemailer from 'nodemailer';

const messages = {
  confirmation: {
    subject: 'Confirme seu e-mail no Gabariteii',
    action: 'Copie o código abaixo e cole na tela de confirmação do Gabariteii.',
    ignore: 'Se você não fez esse cadastro, ignore esta mensagem.',
  },
  recovery: {
    subject: 'Redefina sua senha do Gabariteii',
    action: 'Copie o código abaixo e cole na tela Esqueci minha senha do Gabariteii.',
    ignore: 'Se você não pediu uma nova senha, ignore esta mensagem.',
  },
};

export function createEmailMailer(config) {
  if (!config.SMTP_HOST || !config.SMTP_FROM) {
    return null;
  }

  const secure = config.SMTP_PORT === 465 || config.SMTP_PORT === 2465;
  const local = ['localhost', '127.0.0.1', '::1'].includes(config.SMTP_HOST);
  const transport = nodemailer.createTransport({
    host: config.SMTP_HOST,
    port: config.SMTP_PORT,
    secure,
    requireTLS: !secure && !local,
    ...(config.SMTP_USER ? { auth: { user: config.SMTP_USER, pass: config.SMTP_PASSWORD } } : {}),
    connectionTimeout: 5000,
    greetingTimeout: 5000,
    socketTimeout: 8000,
    disableFileAccess: true,
    disableUrlAccess: true,
  });

  return async (to, token, purpose = 'confirmation') => {
    const { subject, action, ignore } = messages[purpose];
    await transport.sendMail({
      from: { name: 'Gabariteii', address: config.SMTP_FROM },
      to: { name: '', address: to },
      subject,
      text: [action, token, `O código vale por 30 minutos. ${ignore}`].join('\n\n'),
    });
  };
}
