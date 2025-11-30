/**
 * Email Attachment Template
 * Pattern for handling file, buffer, and URL-based attachments
 */

import { Resend } from 'resend';
import fs from 'fs';
import path from 'path';

const resend = new Resend(process.env.RESEND_API_KEY);

interface EmailAttachment {
  filename: string;
  content: Buffer | string;
}

interface EmailWithAttachments {
  from: string;
  to: string;
  subject: string;
  html: string;
  attachments: EmailAttachment[];
}

/**
 * Send email with file attachment
 */
export async function sendWithFileAttachment(
  recipientEmail: string,
  subject: string,
  html: string,
  filePath: string
) {
  try {
    // Validate file exists
    if (!fs.existsSync(filePath)) {
      throw new Error(`File not found: ${filePath}`);
    }

    // Read file
    const fileContent = fs.readFileSync(filePath);
    const fileName = path.basename(filePath);

    const { data, error } = await resend.emails.send({
      from: 'documents@example.com',
      to: recipientEmail,
      subject,
      html,
      attachments: [
        {
          filename: fileName,
          content: fileContent,
        },
      ],
    });

    if (error) {
      console.error('Failed to send email with attachment:', error);
      return { success: false, error: error.message };
    }

    console.log(`Email with attachment sent to ${recipientEmail}`);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('File attachment error:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Send email with buffer attachment
 */
export async function sendWithBufferAttachment(
  recipientEmail: string,
  subject: string,
  html: string,
  buffer: Buffer,
  filename: string
) {
  try {
    const { data, error } = await resend.emails.send({
      from: 'reports@example.com',
      to: recipientEmail,
      subject,
      html,
      attachments: [
        {
          filename,
          content: buffer,
        },
      ],
    });

    if (error) {
      throw new Error(`Failed to send email: ${error.message}`);
    }

    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Buffer attachment error:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Send email with URL-based attachment
 */
export async function sendWithUrlAttachment(
  recipientEmail: string,
  subject: string,
  html: string,
  fileUrl: string,
  filename: string
) {
  try {
    // Fetch file from URL
    const response = await fetch(fileUrl);

    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    const { data, error } = await resend.emails.send({
      from: 'downloads@example.com',
      to: recipientEmail,
      subject,
      html,
      attachments: [
        {
          filename,
          content: buffer,
        },
      ],
    });

    if (error) {
      throw new Error(`Failed to send email: ${error.message}`);
    }

    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('URL attachment error:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Send email with multiple attachments
 */
export async function sendWithMultipleAttachments(
  recipientEmail: string,
  subject: string,
  html: string,
  attachments: EmailAttachment[]
) {
  try {
    // Validate total size (max 25MB)
    const totalSize = attachments.reduce((sum, att) => {
      const size = typeof att.content === 'string'
        ? Buffer.byteLength(att.content)
        : att.content.length;
      return sum + size;
    }, 0);

    if (totalSize > 25 * 1024 * 1024) {
      throw new Error('Total attachment size exceeds 25MB limit');
    }

    const { data, error } = await resend.emails.send({
      from: 'documents@example.com',
      to: recipientEmail,
      subject,
      html,
      attachments,
    });

    if (error) {
      throw new Error(`Failed to send email: ${error.message}`);
    }

    console.log(`Email with ${attachments.length} attachments sent`);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Multiple attachments error:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Validate attachment before sending
 */
export function validateAttachment(filePath: string): { valid: boolean; error?: string } {
  if (!fs.existsSync(filePath)) {
    return { valid: false, error: `File not found: ${filePath}` };
  }

  const stats = fs.statSync(filePath);

  if (stats.size > 25 * 1024 * 1024) {
    return { valid: false, error: 'File exceeds 25MB limit' };
  }

  if (stats.size > 10 * 1024 * 1024) {
    console.warn('File exceeds 10MB recommended size');
  }

  return { valid: true };
}

/**
 * Send invoice email
 */
export async function sendInvoiceEmail(
  customerEmail: string,
  invoiceNumber: string,
  pdfPath: string,
  amount: string
) {
  // Validate attachment
  const validation = validateAttachment(pdfPath);
  if (!validation.valid) {
    return { success: false, error: validation.error };
  }

  const fileContent = fs.readFileSync(pdfPath);

  return resend.emails.send({
    from: 'invoices@example.com',
    to: customerEmail,
    subject: `Invoice #${invoiceNumber}`,
    html: `
      <h2>Invoice #${invoiceNumber}</h2>
      <p>Your invoice is attached below.</p>
      <p><strong>Amount: ${amount}</strong></p>
      <p>Thank you for your business!</p>
    `,
    attachments: [
      {
        filename: `invoice-${invoiceNumber}.pdf`,
        content: fileContent,
      },
    ],
  });
}

/**
 * Send receipt email
 */
export async function sendReceiptEmail(
  customerEmail: string,
  receiptNumber: string,
  receiptPath: string
) {
  return sendWithFileAttachment(
    customerEmail,
    `Receipt #${receiptNumber}`,
    `
      <h2>Receipt #${receiptNumber}</h2>
      <p>Your receipt is attached.</p>
      <p>Thank you for your purchase!</p>
    `,
    receiptPath
  );
}

/**
 * Send certificate email
 */
export async function sendCertificateEmail(
  recipientEmail: string,
  recipientName: string,
  certificatePath: string
) {
  return sendWithFileAttachment(
    recipientEmail,
    `Certificate for ${recipientName}`,
    `
      <h2>Congratulations, ${recipientName}!</h2>
      <p>Your certificate is attached.</p>
      <p>We're proud of your achievement.</p>
    `,
    certificatePath
  );
}

/**
 * Send document with optional attachment
 */
export async function sendDocumentEmail(
  recipientEmail: string,
  subject: string,
  html: string,
  attachmentPath?: string
) {
  const emailPayload: any = {
    from: 'documents@example.com',
    to: recipientEmail,
    subject,
    html,
  };

  // Add attachment if provided and file exists
  if (attachmentPath && fs.existsSync(attachmentPath)) {
    const fileContent = fs.readFileSync(attachmentPath);
    const fileName = path.basename(attachmentPath);

    emailPayload.attachments = [
      {
        filename: fileName,
        content: fileContent,
      },
    ];
  }

  return resend.emails.send(emailPayload);
}

/**
 * Batch emails with same attachment
 */
export async function sendBatchWithAttachment(
  recipients: string[],
  subject: string,
  htmlTemplate: (name: string) => string,
  filePath: string
) {
  const fileContent = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);

  const emails = recipients.map(email => ({
    from: 'documents@example.com',
    to: email,
    subject,
    html: htmlTemplate(email),
    attachments: [
      {
        filename: fileName,
        content: fileContent,
      },
    ],
  }));

  return resend.batch.send(emails);
}

/**
 * Helper to create attachment from string content
 */
export function createStringAttachment(filename: string, content: string): EmailAttachment {
  return {
    filename,
    content: Buffer.from(content, 'utf-8'),
  };
}

/**
 * Helper to create attachment from JSON
 */
export function createJsonAttachment(filename: string, data: any): EmailAttachment {
  return {
    filename,
    content: Buffer.from(JSON.stringify(data, null, 2), 'utf-8'),
  };
}

/**
 * Helper to create attachment from CSV
 */
export function createCsvAttachment(
  filename: string,
  rows: Array<Record<string, string>>
): EmailAttachment {
  const headers = Object.keys(rows[0] || {});
  const csvContent = [
    headers.join(','),
    ...rows.map(row => headers.map(h => `"${row[h] || ''}"`).join(',')),
  ].join('\n');

  return {
    filename,
    content: Buffer.from(csvContent, 'utf-8'),
  };
}
