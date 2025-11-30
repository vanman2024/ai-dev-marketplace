/**
 * Single Email Template
 * Basic pattern for sending individual transactional emails
 */

import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

// Email configuration
interface EmailConfig {
  from: string;
  to: string;
  replyTo?: string;
  subject: string;
  html: string;
  text?: string;
}

/**
 * Send a single email with error handling and logging
 */
export async function sendEmail(config: EmailConfig) {
  try {
    // Validate email address
    if (!config.to.includes('@')) {
      throw new Error(`Invalid email address: ${config.to}`);
    }

    // Send email
    const { data, error } = await resend.emails.send({
      from: config.from,
      to: config.to,
      reply_to: config.replyTo,
      subject: config.subject,
      html: config.html,
      text: config.text,
    });

    // Handle errors
    if (error) {
      console.error('Email send error:', {
        recipient: config.to,
        error: error.message,
        timestamp: new Date().toISOString(),
      });
      return { success: false, error: error.message };
    }

    // Log success
    console.log('Email sent successfully:', {
      recipient: config.to,
      messageId: data.id,
      timestamp: new Date().toISOString(),
    });

    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Email send exception:', {
      recipient: config.to,
      error: err instanceof Error ? err.message : String(err),
      timestamp: new Date().toISOString(),
    });

    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

// Template examples
export const templates = {
  // Welcome email template
  welcome: (firstName: string) => ({
    subject: `Welcome to Example, ${firstName}!`,
    html: `
      <h1>Welcome!</h1>
      <p>Hi ${firstName},</p>
      <p>Thank you for joining us. We're excited to have you on board.</p>
      <a href="https://app.example.com/start" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
        Get Started
      </a>
    `,
  }),

  // Confirmation email template
  confirmation: (email: string, code: string) => ({
    subject: 'Confirm Your Email Address',
    html: `
      <h2>Email Confirmation</h2>
      <p>Please confirm your email address:</p>
      <p><strong>${email}</strong></p>
      <p>
        <a href="https://example.com/confirm?code=${code}">
          Confirm Email
        </a>
      </p>
      <p>Or enter this code: <strong>${code}</strong></p>
      <p>This link expires in 24 hours.</p>
    `,
  }),

  // Password reset template
  passwordReset: (resetLink: string) => ({
    subject: 'Reset Your Password',
    html: `
      <h2>Password Reset Request</h2>
      <p>We received a request to reset your password.</p>
      <p>
        <a href="${resetLink}" style="background: #dc3545; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
          Reset Password
        </a>
      </p>
      <p>Link expires in 1 hour.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    `,
  }),

  // Notification template
  notification: (title: string, message: string, actionUrl?: string) => ({
    subject: title,
    html: `
      <h2>${title}</h2>
      <p>${message}</p>
      ${actionUrl ? `
        <p>
          <a href="${actionUrl}">
            View More
          </a>
        </p>
      ` : ''}
    `,
  }),
};

// Usage examples
export async function sendWelcomeEmail(email: string, firstName: string) {
  const template = templates.welcome(firstName);
  return sendEmail({
    from: 'welcome@example.com',
    to: email,
    subject: template.subject,
    html: template.html,
  });
}

export async function sendConfirmationEmail(email: string, code: string) {
  const template = templates.confirmation(email, code);
  return sendEmail({
    from: 'verify@example.com',
    to: email,
    subject: template.subject,
    html: template.html,
  });
}

export async function sendPasswordResetEmail(email: string, resetLink: string) {
  const template = templates.passwordReset(resetLink);
  return sendEmail({
    from: 'noreply@example.com',
    to: email,
    replyTo: 'support@example.com',
    subject: template.subject,
    html: template.html,
  });
}
