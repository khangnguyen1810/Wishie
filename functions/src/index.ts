import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { buildPrompt, parseGeminiJson } from "./giftPrompt.js";
import { parseGeminiError } from "./geminiError.js";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent";

const MAX_ATTEMPTS = 4;
const RETRYABLE_STATUS = new Set([429, 500, 503]);
// Don't block the function longer than this waiting on a server Retry-After.
const MAX_RETRY_WAIT_MS = 10_000;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Exponential backoff with jitter: ~0.5s, 1s, 2s.
function backoffDelay(attempt: number): number {
  const base = 500 * 2 ** attempt;
  return base + Math.random() * 250;
}

export const suggestGifts = onCall(
  { secrets: [GEMINI_API_KEY] },
  async (request) => {
    const interests = Array.isArray(request.data?.interests)
      ? request.data.interests
      : [];
    const age = typeof request.data?.age === "number" ? request.data.age : null;
    const existingItemNames = Array.isArray(request.data?.existingItemNames)
      ? request.data.existingItemNames
      : [];
    const country =
      typeof request.data?.country === "string" ? request.data.country : null;

    if (interests.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "At least one interest is required.",
      );
    }

    const prompt = buildPrompt({ interests, age, existingItemNames, country });

    const requestInit = {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.9,
          responseMimeType: "application/json",
        },
      }),
    };

    let response: Response | undefined;
    for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
      try {
        response = await fetch(
          `${GEMINI_URL}?key=${GEMINI_API_KEY.value()}`,
          requestInit,
        );
      } catch (err) {
        // Network-level failure: retry unless this was the last attempt.
        if (attempt === MAX_ATTEMPTS - 1) {
          console.error(`Gemini request threw on final attempt: ${err}`);
          throw new HttpsError(
            "unavailable",
            "Could not reach the suggestion service.",
          );
        }
        await sleep(backoffDelay(attempt));
        continue;
      }

      if (response.ok) break;

      const errorBody = await response.text().catch(() => "");
      console.error(
        `Gemini request failed (attempt ${attempt + 1}/${MAX_ATTEMPTS}): ` +
          `${response.status} ${response.statusText} ${errorBody}`,
      );

      // Non-retryable errors (e.g. 400/403/404) won't improve with retries.
      if (!RETRYABLE_STATUS.has(response.status)) {
        throw new HttpsError(
          "unavailable",
          "Suggestion service returned an error.",
        );
      }

      const { isDailyQuota, retryDelayMs } = parseGeminiError(errorBody);

      // A per-day free-tier quota won't recover until it resets; retrying today
      // only burns quota, so fail fast with a message the user can act on.
      if (isDailyQuota) {
        throw new HttpsError(
          "resource-exhausted",
          "You've reached today's gift-suggestion limit. Please try again tomorrow.",
        );
      }

      // No attempts left to spend.
      if (attempt === MAX_ATTEMPTS - 1) break;

      // If the server asks us to wait longer than we're willing to block, give
      // up now rather than holding the request open just to fail again.
      if (retryDelayMs !== null && retryDelayMs > MAX_RETRY_WAIT_MS) {
        throw new HttpsError(
          "unavailable",
          "The suggestion service is busy right now. Please try again.",
        );
      }

      // Honor the server's Retry-After when present, else use our own backoff.
      await sleep(retryDelayMs ?? backoffDelay(attempt));
    }

    if (!response || !response.ok) {
      throw new HttpsError(
        "unavailable",
        "The suggestion service is busy right now. Please try again.",
      );
    }

    const body = await response.json();
    const text = body?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    let parsed;
    try {
      parsed = parseGeminiJson(text);
    } catch {
      throw new HttpsError("internal", "Could not parse suggestions.");
    }

    return { ideas: parsed.ideas.slice(0, 10) };
  },
);
