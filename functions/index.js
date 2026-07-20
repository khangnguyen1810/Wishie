const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { buildPrompt, parseGeminiJson } = require("./giftPrompt");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

exports.suggestGifts = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const interests = Array.isArray(request.data?.interests) ? request.data.interests : [];
  const age = typeof request.data?.age === "number" ? request.data.age : null;
  const existingItemNames = Array.isArray(request.data?.existingItemNames)
    ? request.data.existingItemNames
    : [];

  if (interests.length === 0) {
    throw new HttpsError("invalid-argument", "At least one interest is required.");
  }

  const prompt = buildPrompt({ interests, age, existingItemNames });

  let response;
  try {
    response = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY.value()}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.9, responseMimeType: "application/json" },
      }),
    });
  } catch (err) {
    throw new HttpsError("unavailable", "Could not reach the suggestion service.");
  }

  if (!response.ok) {
    throw new HttpsError("unavailable", "Suggestion service returned an error.");
  }

  const body = await response.json();
  const text = body?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  let parsed;
  try {
    parsed = parseGeminiJson(text);
  } catch (err) {
    throw new HttpsError("internal", "Could not parse suggestions.");
  }

  return { ideas: parsed.ideas.slice(0, 10) };
});
