const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const OpenAI = require("openai");

initializeApp();

const openAiApiKey = defineSecret("OPENAI_API_KEY");

exports.askFinanceAssistant = onRequest(
  {
    region: "asia-southeast2",
    cors: true,
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Method not allowed" });
      return;
    }

    const authorization = request.headers.authorization || "";
    if (!authorization.startsWith("Bearer ")) {
      response.status(401).json({ error: "Authentication required" });
      return;
    }

    try {
      await getAuth().verifyIdToken(authorization.substring(7));
      const question = String(request.body?.question || "").trim();
      if (!question || question.length > 2000) {
        response.status(400).json({ error: "Invalid question" });
        return;
      }

      const history = Array.isArray(request.body?.history)
        ? request.body.history.slice(-10).map((item) => ({
            role: item.role === "assistant" ? "assistant" : "user",
            content: String(item.content || "").slice(0, 4000),
          }))
        : [];

      const client = new OpenAI({ apiKey: openAiApiKey.value() });
      const result = await client.responses.create({
        model: process.env.OPENAI_MODEL || "gpt-6-luna",
        instructions:
          "You are the in-app help assistant for Finance Project. Answer in the user's language. Help with app usage and general personal-finance education. Be concise, practical, and never claim to be a licensed financial adviser. Do not provide guaranteed returns or request secrets, passwords, card numbers, or authentication codes.",
        input: [...history, { role: "user", content: question }],
        max_output_tokens: 700,
      });

      response.json({ answer: result.output_text });
    } catch (error) {
      console.error("askFinanceAssistant failed", error);
      response.status(500).json({ error: "Unable to answer right now" });
    }
  },
);
