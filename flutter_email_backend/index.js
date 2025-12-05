const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const puppeteer = require('puppeteer');

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: 'gmail',
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'c62425773@gmail.com',
    pass: 'sirhtrlijukmrgkq'
  },
  tls: {
    rejectUnauthorized: false
  }
});

// Helper to convert Firestore Timestamp to Date
function firestoreTimestampToDate(timestamp) {
  if (!timestamp) return new Date();
  if (timestamp.toDate) return timestamp.toDate(); // If it's a Firestore Timestamp object
  if (typeof timestamp === 'object' && timestamp.seconds !== undefined) {
    return new Date(timestamp.seconds * 1000 + (timestamp.nanoseconds || 0) / 1000000);
  }
  return new Date(timestamp); // Fallback if it's a string or other
}

// Generate invoice HTML
function generateInvoiceHtml(order) {
  // Parse order structure from Flutter/Firestore
  const id = order.orderId || order.id || 'Unknown';
  const date = firestoreTimestampToDate(order.orderDate || order.createdAt || new Date());

  // Customer details
  const customerName = order.customerName || 'Unknown Customer';
  const customerEmail = order.customerEmail || '';
  const shippingAddress = order.shippingAddress || {};
  const customerAddress = [
    shippingAddress.line1 || '',
    shippingAddress.line2 || '',
    shippingAddress.city || '',
    `${shippingAddress.state || ''} ${shippingAddress.pincode || ''}`.trim()
  ].filter(Boolean).join(', ');

  // Items mapping
  const items = (order.items || []).map(i => ({
    name: i.productTitle || i.name || 'Unknown Item',
    price: parseFloat(i.productPrice || i.price || 0),
    quantity: parseInt(i.quantity || 1)
  }));

  // Calculations
  const subtotal = items.reduce((s, it) => s + it.price * it.quantity, 0);
  const tax = order.tax || 0;
  const shipping = order.shipping || 0;
  const total = subtotal + tax + shipping;

  // Seller defaults to BUY APP
  const gstin = '27AAACS1234R1Z5'; // Placeholder GSTIN number
  const sellerEmail = 'info@buyapp.com';

  const itemsRows = items.map(i => `
    <tr>
      <td style="padding:8px;border:1px solid #ddd;">${i.name}</td>
      <td style="padding:8px;border:1px solid #ddd;text-align:right;">${i.quantity}</td>
      <td style="padding:8px;border:1px solid #ddd;text-align:right;">${(i.price).toFixed(2)}</td>
      <td style="padding:8px;border:1px solid #ddd;text-align:right;">${(i.price * i.quantity).toFixed(2)}</td>
    </tr>`).join('');

  return `
  <!doctype html>
  <html>
    <head>
      <meta charset="utf-8"/>
      <title>Invoice ${id}</title>
    </head>
    <body style="font-family:Arial,Helvetica,sans-serif;margin:0;padding:20px;color:#333;">
      <h1 style="margin-bottom:0;">Invoice</h1>
      <p style="margin-top:4px;">Order: ${id} &nbsp;|&nbsp; Date: ${date.toLocaleString()}</p>

      <table style="width:100%;margin-top:20px;">
        <tr>
          <td style="vertical-align:top;width:50%;">
            <strong>From</strong>
            <div><strong>BUY APP</strong></div>
            <div>GSTIN: ${gstin}</div>
            <div>${sellerEmail}</div>
          </td>
          <td style="vertical-align:top;width:50%;">
            <strong>To</strong>
            <div>${customerName}</div>
            <div>${customerEmail}</div>
            <div>${customerAddress}</div>
          </td>
        </tr>
      </table>

      <table style="width:100%;border-collapse:collapse;margin-top:20px;">
        <thead>
          <tr>
            <th style="padding:8px;border:1px solid #ddd;text-align:left;background:#f5f5f5;">Item</th>
            <th style="padding:8px;border:1px solid #ddd;background:#f5f5f5;">Qty</th>
            <th style="padding:8px;border:1px solid #ddd;background:#f5f5f5;text-align:right;">Price</th>
            <th style="padding:8px;border:1px solid #ddd;background:#f5f5f5;text-align:right;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${itemsRows}
        </tbody>
        <tfoot>
          <tr>
            <td colspan="2"></td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">Subtotal</td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">${subtotal.toFixed(2)}</td>
          </tr>
          <tr>
            <td colspan="2"></td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">Tax</td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">${tax.toFixed(2)}</td>
          </tr>
          <tr>
            <td colspan="2"></td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">Shipping</td>
            <td style="padding:8px;border:1px solid #ddd;text-align:right;">${shipping.toFixed(2)}</td>
          </tr>
          <tr>
            <td colspan="2"></td>
            <td style="padding:8px;border:1px solid #ddd;font-weight:bold;text-align:right;">Total</td>
            <td style="padding:8px;border:1px solid #ddd;font-weight:bold;text-align:right;">${total.toFixed(2)}</td>
          </tr>
        </tfoot>
      </table>

      <p style="margin-top:30px;font-size:12px;color:#666;">Thank you for your purchase.</p>
    </body>
  </html>`;
}

// Convert HTML to PDF buffer
async function htmlToPdfBuffer(html) {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });
    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '20px', bottom: '20px', left: '20px', right: '20px' }
    });
    return pdfBuffer;
  } finally {
    await browser.close();
  }
}

app.post('/send', async (req, res) => {
  const { to, subject, text, html: htmlContent, message, order } = req.body;

  const htmlBody = htmlContent || message || `<p>${text || ''}</p>`;
  const textBody = text || message || '';

  console.log(`📧 Attempting to send email to: ${to}`);
  console.log(`📧 Subject: ${subject}`);
  console.log(`📧 Order provided: ${!!order}`);
  if (order) {
    console.log(`📧 Order ID: ${order.orderId || order.id}`);
  }

  try {
    const mailOptions = {
      from: '"BUY APP" <c62425773@gmail.com>',
      to: to,
      subject: subject,
      text: textBody,
      html: htmlBody
    };

    let pdfAttached = false;

    // If order data is provided, generate and attach PDF invoice
      if (order) {
          console.log(`📄 Generating invoice PDF for order: ${order.orderId || order.id}`);
          try {
              const invoiceHtml = generateInvoiceHtml(order);
              const pdfBuffer = await htmlToPdfBuffer(invoiceHtml);
              console.log(`📄 PDF generated successfully, size: ${pdfBuffer.length} bytes`);

              const orderId = order.orderId || order.id || 'unknown';

              // Validate PDF buffer before attaching
              if (pdfBuffer && pdfBuffer.length > 0) {
                  mailOptions.attachments = [
                      {
                          filename: `invoice-${orderId}.pdf`,
                          content: pdfBuffer,
                          contentType: 'application/pdf'
                      }
                  ];
                  console.log(`📎 PDF attachment added to email with filename: invoice-${orderId}.pdf`);
                  pdfAttached = true;
              } else {
                  console.error('❌ PDF buffer is empty or invalid');
              }
          } catch (pdfError) {
              console.error('❌ PDF generation failed:', pdfError);
          }
      } else {
          console.log('⚠️ No order provided, skipping PDF attachment');
      }


      const info = await transporter.sendMail(mailOptions);

    console.log('✅ Email sent successfully:', info.messageId);
    res.status(200).json({
      success: true,
      message: 'Email sent successfully',
      messageId: info.messageId,
      pdfAttached
    });
  } catch (error) {
    console.error('❌ Email sending failed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send email',
      error: error.message
    });
  }
});

app.get('/', (req, res) => {
  res.status(200).json({ status: 'Server is running', timestamp: new Date() });
});

// New endpoint for sending order receipt with PDF attachment
app.post('/send/receipt', async (req, res) => {
  try {
    const { customerEmail, customerName, orderId, pdfBase64, pdfFileName } = req.body;

    console.log(`📧 Sending receipt email to: ${customerEmail} for Order: ${orderId}`);

    // Convert base64 to buffer for attachment
    const pdfBuffer = Buffer.from(pdfBase64, 'base64');

    const mailOptions = {
      from: 'c62425773@gmail.com',
      to: customerEmail,
      subject: pdfFileName.includes('Invoice') ? `Invoice - ${orderId}` : `Order Receipt - ${orderId}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #1976D2; color: white; padding: 20px; text-align: center;">
            <h1>${pdfFileName.includes('Invoice') ? '📄 Invoice' : '🧾 Order Receipt'}</h1>
          </div>
          
          <div style="padding: 20px; background-color: #f9f9f9;">
            <h2>Dear ${customerName},</h2>
            
            <p>Thank you for your order! ${pdfFileName.includes('Invoice') ? 'Please find your invoice attached as a PDF.' : 'Please find your detailed order receipt attached as a PDF.'}</p>
            
            <div style="background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="color: #1976D2; margin-top: 0;">${pdfFileName.includes('Invoice') ? 'Invoice Information' : 'Order Information'}</h3>
              <p><strong>${pdfFileName.includes('Invoice') ? 'Invoice' : 'Order'} ID:</strong> ${orderId}</p>
              <p><strong>Date:</strong> ${new Date().toLocaleDateString()}</p>
            </div>
            
            <div style="background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h4 style="margin-top: 0; color: #1565C0;">📎 Attachment</h4>
              <p>Your ${pdfFileName.includes('Invoice') ? 'invoice' : 'detailed order receipt'} is attached as a PDF file: <strong>${pdfFileName}</strong></p>
            </div>
            
            ${pdfFileName.includes('Invoice') ? 
              '<div style="background-color: #fff3e0; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ff9800;"><p><strong>💳 Payment Information:</strong><br>This invoice serves as your official receipt. Please keep it for your records.</p></div>' 
              : ''}
            
            <p>If you have any questions about your ${pdfFileName.includes('Invoice') ? 'invoice' : 'order'}, please don\'t hesitate to contact our customer support.</p>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px;">
              <p>Thank you for choosing us!</p>
              <p><em>This is an automated email. Please do not reply to this message.</em></p>
            </div>
          </div>
        </div>
      `,
      attachments: [
        {
          filename: pdfFileName,
          content: pdfBuffer,
          contentType: 'application/pdf'
        }
      ]
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ Receipt email with PDF sent successfully to: ${customerEmail}`);
    
    res.status(200).json({ 
      success: true, 
      message: 'Receipt email with PDF sent successfully',
      orderId: orderId
    });

  } catch (error) {
    console.error('❌ Error sending receipt email:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send receipt email',
      details: error.message 
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`📧 Email server running on port ${PORT}`);
  console.log(`📧 Ready to send emails from Gmail to any provider (including Yahoo)`);
});