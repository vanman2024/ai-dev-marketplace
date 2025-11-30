# Email Attachments

Patterns for handling file attachments in emails including files, buffers, and URLs.

## Use Cases

- Invoice attachments
- Document sharing
- Report delivery
- Receipt emails
- Contract distribution
- Certificate delivery

## TypeScript Example

### File-Based Attachment

```typescript
import { Resend } from 'resend';
import fs from 'fs';
import path from 'path';

const resend = new Resend(process.env.RESEND_API_KEY);

async function sendInvoiceEmail(
  customerEmail: string,
  invoicePath: string,
  invoiceNumber: string
) {
  try {
    // Read file from disk
    const fileContent = fs.readFileSync(invoicePath);
    const fileName = path.basename(invoicePath);

    const { data, error } = await resend.emails.send({
      from: 'invoices@example.com',
      to: customerEmail,
      subject: `Invoice #${invoiceNumber}`,
      html: `
        <h2>Invoice #${invoiceNumber}</h2>
        <p>Your invoice is attached below.</p>
        <p>Thank you for your business!</p>
      `,
      attachments: [
        {
          filename: `invoice-${invoiceNumber}.pdf`,
          content: fileContent,
        },
      ],
    });

    if (error) {
      throw new Error(`Failed to send invoice: ${error.message}`);
    }

    console.log(`Invoice email sent to ${customerEmail}`);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Invoice send error:', err);
    return { success: false, error: err instanceof Error ? err.message : String(err) };
  }
}
```

### Buffer-Based Attachment

```typescript
import { Resend } from 'resend';
import { PDFDocument, rgb } from 'pdf-lib';

const resend = new Resend(process.env.RESEND_API_KEY);

async function sendGeneratedReportEmail(
  userEmail: string,
  reportData: { title: string; content: string; date: Date }
) {
  try {
    // Generate PDF in memory
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([600, 800]);

    page.drawText(reportData.title, { x: 50, y: 750, size: 24 });
    page.drawText(reportData.content, { x: 50, y: 700, size: 12 });
    page.drawText(`Generated: ${reportData.date.toISOString()}`, {
      x: 50,
      y: 50,
      size: 10,
    });

    const pdfBuffer = await pdfDoc.save();

    const { data, error } = await resend.emails.send({
      from: 'reports@example.com',
      to: userEmail,
      subject: `Report: ${reportData.title}`,
      html: `
        <h2>${reportData.title}</h2>
        <p>Your report has been generated and is attached.</p>
        <p>Generated: ${reportData.date.toLocaleDateString()}</p>
      `,
      attachments: [
        {
          filename: `${reportData.title}-${Date.now()}.pdf`,
          content: Buffer.from(pdfBuffer),
        },
      ],
    });

    if (error) {
      throw new Error(`Failed to send report: ${error.message}`);
    }

    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Report send error:', err);
    return { success: false, error: err instanceof Error ? err.message : String(err) };
  }
}
```

### URL-Based Attachment

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

async function sendWithUrlAttachment(
  recipientEmail: string,
  fileUrl: string,
  fileName: string
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
      subject: 'Your Download',
      html: `
        <h2>Download Ready</h2>
        <p>Your file is attached below.</p>
      `,
      attachments: [
        {
          filename: fileName,
          content: buffer,
        },
      ],
    });

    if (error) {
      throw new Error(`Failed to send attachment: ${error.message}`);
    }

    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('Download email error:', err);
    return { success: false, error: err instanceof Error ? err.message : String(err) };
  }
}
```

### Multiple Attachments

```typescript
interface EmailAttachment {
  filename: string;
  content: Buffer | string;
}

async function sendWithMultipleAttachments(
  recipientEmail: string,
  attachments: EmailAttachment[]
) {
  // Validate attachment size (total should be < 25MB)
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
    subject: 'Your Documents',
    html: `
      <h2>Documents</h2>
      <p>Please find ${attachments.length} document(s) attached.</p>
      <ul>
        ${attachments.map(att => `<li>${att.filename}</li>`).join('\n')}
      </ul>
    `,
    attachments: attachments,
  });

  return { success: !error, messageId: data?.id, error };
}
```

### Conditional Attachment Handling

```typescript
async function sendEmailWithOptionalAttachment(
  recipientEmail: string,
  subject: string,
  html: string,
  attachmentPath?: string
) {
  const emailPayload: any = {
    from: 'notifications@example.com',
    to: recipientEmail,
    subject,
    html,
  };

  // Only add attachment if provided and file exists
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
```

## Python Example

### File-Based Attachment

```python
import os
from pathlib import Path
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_invoice_email(
    customer_email: str,
    invoice_path: str,
    invoice_number: str,
):
    """Send email with invoice attachment."""
    try:
        # Read file from disk
        with open(invoice_path, "rb") as f:
            file_content = f.read()

        file_name = Path(invoice_path).name

        email = {
            "from": "invoices@example.com",
            "to": customer_email,
            "subject": f"Invoice #{invoice_number}",
            "html": f"""
                <h2>Invoice #{invoice_number}</h2>
                <p>Your invoice is attached below.</p>
                <p>Thank you for your business!</p>
            """,
            "attachments": [
                {
                    "filename": f"invoice-{invoice_number}.pdf",
                    "content": file_content,
                }
            ],
        }

        response = client.emails.send(email)

        if response.get("error"):
            raise Exception(f"Failed to send invoice: {response['error']}")

        print(f"Invoice email sent to {customer_email}")
        return {"success": True, "message_id": response["data"]["id"]}

    except Exception as err:
        print(f"Invoice send error: {str(err)}")
        return {"success": False, "error": str(err)}
```

### Buffer-Based Attachment

```python
import os
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_generated_report_email(
    user_email: str,
    report_data: dict,
):
    """Send email with generated PDF report."""
    try:
        # Generate PDF in memory
        pdf_buffer = BytesIO()
        pdf_canvas = canvas.Canvas(pdf_buffer, pagesize=letter)

        pdf_canvas.drawString(50, 750, report_data["title"])
        pdf_canvas.drawString(50, 700, report_data["content"])
        pdf_canvas.drawString(
            50,
            50,
            f"Generated: {datetime.now().isoformat()}",
        )

        pdf_canvas.save()
        pdf_buffer.seek(0)

        email = {
            "from": "reports@example.com",
            "to": user_email,
            "subject": f"Report: {report_data['title']}",
            "html": f"""
                <h2>{report_data['title']}</h2>
                <p>Your report has been generated and is attached.</p>
                <p>Generated: {datetime.now().strftime('%Y-%m-%d')}</p>
            """,
            "attachments": [
                {
                    "filename": f"{report_data['title']}-{int(datetime.now().timestamp())}.pdf",
                    "content": pdf_buffer.getvalue(),
                }
            ],
        }

        response = client.emails.send(email)

        if response.get("error"):
            raise Exception(f"Failed to send report: {response['error']}")

        return {"success": True, "message_id": response["data"]["id"]}

    except Exception as err:
        print(f"Report send error: {str(err)}")
        return {"success": False, "error": str(err)}
```

### URL-Based Attachment

```python
import os
import requests
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_with_url_attachment(
    recipient_email: str,
    file_url: str,
    file_name: str,
):
    """Send email with attachment from URL."""
    try:
        # Fetch file from URL
        response = requests.get(file_url)
        response.raise_for_status()

        file_content = response.content

        email = {
            "from": "downloads@example.com",
            "to": recipient_email,
            "subject": "Your Download",
            "html": """
                <h2>Download Ready</h2>
                <p>Your file is attached below.</p>
            """,
            "attachments": [
                {
                    "filename": file_name,
                    "content": file_content,
                }
            ],
        }

        response = client.emails.send(email)

        if response.get("error"):
            raise Exception(f"Failed to send attachment: {response['error']}")

        return {"success": True, "message_id": response["data"]["id"]}

    except Exception as err:
        print(f"Download email error: {str(err)}")
        return {"success": False, "error": str(err)}
```

### Multiple Attachments

```python
import os
from typing import List, Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_with_multiple_attachments(
    recipient_email: str,
    attachments: List[Dict],
):
    """Send email with multiple attachments."""
    # Validate attachment size (total should be < 25MB)
    total_size = sum(
        len(att["content"]) if isinstance(att["content"], bytes)
        else len(att["content"].encode())
        for att in attachments
    )

    if total_size > 25 * 1024 * 1024:
        raise ValueError("Total attachment size exceeds 25MB limit")

    email = {
        "from": "documents@example.com",
        "to": recipient_email,
        "subject": "Your Documents",
        "html": f"""
            <h2>Documents</h2>
            <p>Please find {len(attachments)} document(s) attached.</p>
            <ul>
                {"".join(f"<li>{att['filename']}</li>" for att in attachments)}
            </ul>
        """,
        "attachments": attachments,
    }

    response = client.emails.send(email)

    return {
        "success": not response.get("error"),
        "message_id": response.get("data", {}).get("id"),
        "error": response.get("error"),
    }
```

### Conditional Attachment

```python
import os
from pathlib import Path
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_email_with_optional_attachment(
    recipient_email: str,
    subject: str,
    html: str,
    attachment_path: str = None,
):
    """Send email with optional attachment."""
    email_payload = {
        "from": "notifications@example.com",
        "to": recipient_email,
        "subject": subject,
        "html": html,
    }

    # Only add attachment if provided and file exists
    if attachment_path and Path(attachment_path).exists():
        with open(attachment_path, "rb") as f:
            file_content = f.read()

        file_name = Path(attachment_path).name

        email_payload["attachments"] = [
            {
                "filename": file_name,
                "content": file_content,
            }
        ]

    return client.emails.send(email_payload)
```

## File Size Limits

- **Maximum per attachment**: No hard limit
- **Maximum total per email**: 25MB
- **Recommended max**: 5-10MB (for delivery reliability)

## Supported File Types

- **Documents**: PDF, Word (.docx), Excel (.xlsx), PowerPoint (.pptx)
- **Archives**: ZIP, TAR, GZ
- **Images**: PNG, JPG, GIF
- **Text**: CSV, TXT, JSON, XML
- **Other**: Any binary file

## Best Practices

1. **Validate File Existence** - Check files exist before sending
2. **Check File Size** - Warn users about large attachments
3. **Use Descriptive Names** - Make filenames user-friendly
4. **Compress When Possible** - Use ZIP for multiple files
5. **Add File Info in Email** - Tell users what's attached
6. **Handle Missing Files** - Provide fallback content
7. **Scan for Malware** - Validate before sending in production
8. **Set Reasonable Timeouts** - Don't wait too long for downloads
9. **Log Attachment Operations** - Track what was sent
10. **Test with Real Files** - Verify attachments work

## Error Handling

```typescript
// Validate before sending
function validateAttachment(filePath: string): boolean {
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    return false;
  }

  const stats = fs.statSync(filePath);
  if (stats.size > 25 * 1024 * 1024) {
    console.error('File exceeds 25MB limit');
    return false;
  }

  return true;
}
```

## Real-World Example: Invoice System

```typescript
async function sendInvoiceWithReceipt(
  customerId: string,
  invoiceNumber: string,
  pdfPath: string,
) {
  // Validate
  if (!fs.existsSync(pdfPath)) {
    return { success: false, error: 'Invoice PDF not found' };
  }

  // Get customer email
  const customer = await getCustomer(customerId);

  // Read invoice
  const invoiceContent = fs.readFileSync(pdfPath);

  // Send
  const { data, error } = await resend.emails.send({
    from: 'invoices@company.com',
    to: customer.email,
    cc: [customer.accountManagerEmail],
    subject: `Invoice #${invoiceNumber} from Company`,
    html: `
      <h2>Invoice #${invoiceNumber}</h2>
      <p>Dear ${customer.name},</p>
      <p>Please find your invoice attached.</p>
      <p>Payment terms: Net 30 days</p>
    `,
    attachments: [{
      filename: `invoice-${invoiceNumber}.pdf`,
      content: invoiceContent,
    }],
  });

  if (error) {
    // Log failure
    await logEmailFailure(customerId, invoiceNumber, error.message);
    return { success: false, error: error.message };
  }

  // Log success
  await logEmailSent(customerId, invoiceNumber, data.id);
  return { success: true, messageId: data.id };
}
```
