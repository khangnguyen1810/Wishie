import test from "node:test";
import assert from "node:assert/strict";
import { parseGeminiError } from "./geminiError.js";

const DAILY_QUOTA_BODY = JSON.stringify({
  error: {
    code: 429,
    message: "You exceeded your current quota",
    status: "RESOURCE_EXHAUSTED",
    details: [
      {
        "@type": "type.googleapis.com/google.rpc.QuotaFailure",
        violations: [
          {
            quotaMetric:
              "generativelanguage.googleapis.com/generate_content_free_tier_requests",
            quotaId: "GenerateRequestsPerDayPerProjectPerModel-FreeTier",
            quotaDimensions: { location: "global", model: "gemini-3.5-flash" },
            quotaValue: "20",
          },
        ],
      },
      {
        "@type": "type.googleapis.com/google.rpc.RetryInfo",
        retryDelay: "41s",
      },
    ],
  },
});

test("parseGeminiError flags per-day quota exhaustion", () => {
  const info = parseGeminiError(DAILY_QUOTA_BODY);
  assert.equal(info.isDailyQuota, true);
});

test("parseGeminiError reads retryDelay into milliseconds", () => {
  const info = parseGeminiError(DAILY_QUOTA_BODY);
  assert.equal(info.retryDelayMs, 41000);
});

test("parseGeminiError parses fractional-second retryDelay", () => {
  const body = JSON.stringify({
    error: {
      details: [
        {
          "@type": "type.googleapis.com/google.rpc.RetryInfo",
          retryDelay: "0.5s",
        },
      ],
    },
  });
  assert.equal(parseGeminiError(body).retryDelayMs, 500);
});

test("parseGeminiError does not flag per-minute rate limits as daily", () => {
  const body = JSON.stringify({
    error: {
      details: [
        {
          "@type": "type.googleapis.com/google.rpc.QuotaFailure",
          violations: [
            { quotaId: "GenerateRequestsPerMinutePerProjectPerModel-FreeTier" },
          ],
        },
      ],
    },
  });
  const info = parseGeminiError(body);
  assert.equal(info.isDailyQuota, false);
});

test("parseGeminiError returns neutral defaults for non-JSON bodies", () => {
  const info = parseGeminiError("502 Bad Gateway");
  assert.equal(info.isDailyQuota, false);
  assert.equal(info.retryDelayMs, null);
});
