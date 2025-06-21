const express = require('express');
const app = express();
app.use(express.json());

app.post('/api/chat', async (req, res) => {
    const userMessage = req.body.message;
    // Platzhalterantwort – hier kommt später die KI-Logik hin
    res.json({ reply: "GEOK antwortet: '" + userMessage + "' (Beta)" });
});

app.listen(3000, () => console.log("GEOK-Backend aktiv auf Port 3000"));