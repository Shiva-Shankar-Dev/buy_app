const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'c62425773@gmail.com',           // 🔁 Replace with your Gmail address
    pass: 'sirhtrlijukmrgkq' // 🔁 Replace with App Password (no spaces)
  }
});

app.post('/send', async (req, res) => {
  const { to, subject, text } = req.body;

  try {
    await transporter.sendMail({
      from: 'yourgmail@gmail.com',
      to,
      subject,
      text
    });

    res.status(200).send('✅ Email sent successfully');
  } catch (error) {
    console.error('❌ Email sending failed:', error);
    res.status(500).send('❌ Failed to send email');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

