const nodemailer = require('nodemailer');

/**
 * sendTestEmail
 * - By default this uses local MailHog on 127.0.0.1:1025 for development.
 * - To actually deliver emails (not queue/capture), set SMTP_HOST to your real SMTP server
 *   and provide SMTP_USER and SMTP_PASS (if required). Example env vars:
 *     SMTP_HOST=smtp.sendgrid.net
 *     SMTP_PORT=587
 *     SMTP_USER=apikey
 *     SMTP_PASS=<your-api-key>
 *     SMTP_SECURE=false
 *
 * The function will construct an authenticated transporter when credentials are provided.
 */
async function sendTestEmail(to, subject, text) {
  // Default to IPv4 loopback for local dev (MailHog)
  const smtpHost = process.env.SMTP_HOST || '127.0.0.1';
  const smtpPort = parseInt(process.env.SMTP_PORT || '1025', 10);
  const smtpUser = process.env.SMTP_USER || '';
  const smtpPass = process.env.SMTP_PASS || '';
  const smtpSecure = (process.env.SMTP_SECURE || 'false').toLowerCase() === 'true';

  const transportOptions = {
    host: smtpHost,
    port: smtpPort,
    secure: smtpSecure, // true for 465, false for other ports (587)
    tls: { rejectUnauthorized: false },
  };

  // If SMTP credentials are provided, use auth (this will send via the real SMTP server)
  if (smtpUser && smtpPass) {
    transportOptions.auth = {
      user: smtpUser,
      pass: smtpPass,
    };
    // Use connection pooling for real SMTP providers where appropriate
    transportOptions.pool = true;
  }

  const transporter = nodemailer.createTransport(transportOptions);

  // Support a dev/testing override: send all outgoing mail to a single address
  // Set FORCE_SEND_TO in your .env to an email (e.g. FORCE_SEND_TO=jahnviaghera@gmail.com)
  const forceSendTo = process.env.FORCE_SEND_TO || '';
  const originalTo = to;
  const finalTo = forceSendTo ? forceSendTo : to;

  const mailOptions = {
    // Set From header with a friendly name and ensure the SMTP 'envelope' uses MAIL_FROM
    from: `${process.env.MAIL_FROM_NAME || 'Infinicard'} <${process.env.MAIL_FROM || 'no-reply@infinicard.app'}>`,
    to: finalTo,
    subject,
    text,
    html: `<pre>${text}</pre>`,
    envelope: {
      from: process.env.MAIL_FROM || 'no-reply@infinicard.app',
      to: Array.isArray(finalTo) ? finalTo : [finalTo],
    },
    replyTo: process.env.REPLY_TO || process.env.SMTP_USER || process.env.MAIL_FROM,
  };

  // Preserve original recipients for inspection when forcing delivery
  if (forceSendTo) {
    mailOptions.headers = Object.assign({}, mailOptions.headers, {
      'X-Original-To': Array.isArray(originalTo) ? originalTo.join(', ') : originalTo,
      'X-Forced-Delivery-To': forceSendTo,
    });
  }

  const info = await transporter.sendMail(mailOptions);

  return info;
}

// Send a welcome email (simple template)
async function sendWelcomeEmail(to, name, extraText = '') {
  const subject = `Welcome to Infinicard, ${name || ''}`.trim();
  const text = `Hi ${name || 'there'},\n\nWelcome to Infinicard! ${extraText}\n\nCheers,\nInfinicard Team`;
  return sendTestEmail(to, subject, text);
}

// Send an OTP email (for forgot password / verification)
async function sendOtpEmail(to, otp, purpose = 'verification') {
  const subject = `Your ${purpose} code for Infinicard`;
  const text = `Your ${purpose} code is: ${otp}\n\nThis code is valid for 10 minutes. If you did not request this, ignore this email.`;
  return sendTestEmail(to, subject, text);
}

module.exports = { sendTestEmail, sendWelcomeEmail, sendOtpEmail };
