const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: 'gmail',
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'c62425773@gmail.com',           // Your Gmail address
    pass: 'sirhtrlijukmrgkq' // App Password (no spaces)
  },
  tls: {
    rejectUnauthorized: false
  }
});

app.post('/send', async (req, res) => {
  const { to, subject, text, html, message } = req.body;

  // Prefer html > message > text
  const htmlBody = html || message || `<p>${text || ''}</p>`;
  const textBody = text || message || '';

  console.log(`📧 Attempting to send email to: ${to}`);
  console.log(`📧 Subject: ${subject}`);

  try {
    const info = await transporter.sendMail({
      from: '"Your App" <c62425773@gmail.com>',
      to: to,
      subject: subject,
      text: textBody,
      html: htmlBody
    });

    console.log('✅ Email sent successfully:', info.messageId);
    res.status(200).json({ 
      success: true, 
      message: 'Email sent successfully',
      messageId: info.messageId 
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'Server is running', timestamp: new Date() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`📧 Email server running on port ${PORT}`);
  console.log(`📧 Ready to send emails from Gmail to any provider (including Yahoo)`);
});


