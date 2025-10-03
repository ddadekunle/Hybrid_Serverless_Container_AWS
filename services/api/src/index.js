const express = require('express');
const app = express();

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/', (req, res) => res.send('Hybrid serverless + containers API'));

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on ${port}`));
