// services/api/src/index.js
import express from 'express';

const app = express();
app.use(express.json());

// k8s probes (you said your probes hit /health)
app.get('/health', (_req, res) => res.status(200).json({ ok: true }));

app.get('/', (_req, res) => res.status(200).send('api up'));

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on ${port}`));
