const express = require('express');
const os = require('os');
const app = express();

const PORT = process.env.PORT || 3000;

// گرفتن hostname
const hostname = os.hostname();

// گرفتن AZ (در AWS بعداً override می‌کنیم)
const availabilityZone = process.env.AZ || "unknown";

// root endpoint
app.get('/', (req, res) => {
  res.send(`
    <h1>Cloud Capstone App</h1>
    <p><strong>Hostname:</strong> ${hostname}</p>
    <p><strong>Availability Zone:</strong> ${availabilityZone}</p>
    <p><strong>Status:</strong> Running</p>
  `);
});

// health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: "ok" });
});

// info endpoint
app.get('/info', (req, res) => {
  res.json({
    hostname,
    availabilityZone,
    status: "running"
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
