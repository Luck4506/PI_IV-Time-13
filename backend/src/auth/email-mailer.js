import nodemailer from 'nodemailer';

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

  return async (to, token) => {
    await transport.sendMail({
      from: { name: 'Gabariteii', address: config.SMTP_FROM },
      to: { name: '', address: to },
      subject: 'Confirme seu e-mail no Gabariteii',
      text: [
        'Copie o código abaixo e cole na tela de confirmação do Gabariteii.',
        token,
        'O código vale por 30 minutos. Se você não fez esse cadastro, ignore esta mensagem.',
      ].join('\n\n'),
    });
  };
}
