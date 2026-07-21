export interface GeminiErrorInfo {
  /**
   * True when the failure is a per-day free-tier quota being exhausted. These
   * won't recover until the quota resets, so retrying today is pointless.
   */
  isDailyQuota: boolean;
  /**
   * The server-requested wait before retrying, in milliseconds, parsed from the
   * RetryInfo detail (e.g. "41s"). Null when the response carries no hint.
   */
  retryDelayMs: number | null;
}

// Parses protobuf-style Duration strings like "41s" or "0.5s" into ms.
function parseDurationMs(value: unknown): number | null {
  if (typeof value !== "string") return null;
  const match = value.match(/^([\d.]+)s$/);
  if (!match) return null;
  const seconds = Number(match[1]);
  return Number.isFinite(seconds) ? Math.round(seconds * 1000) : null;
}

/**
 * Inspects a Gemini error response body to decide how to react to a failure.
 * Tolerant of unexpected shapes: anything it can't understand yields the
 * neutral default (retryable via caller's own backoff).
 */
export function parseGeminiError(body: string): GeminiErrorInfo {
  let isDailyQuota = false;
  let retryDelayMs: number | null = null;

  try {
    const details = JSON.parse(body)?.error?.details;
    if (Array.isArray(details)) {
      for (const detail of details) {
        const type = String(detail?.["@type"] ?? "");

        if (type.includes("QuotaFailure") && Array.isArray(detail?.violations)) {
          for (const violation of detail.violations) {
            const quotaId = String(violation?.quotaId ?? "");
            if (/PerDay/i.test(quotaId)) {
              isDailyQuota = true;
            }
          }
        }

        if (type.includes("RetryInfo")) {
          retryDelayMs = parseDurationMs(detail?.retryDelay);
        }
      }
    }
  } catch {
    // Non-JSON or unexpected body: fall through to the neutral default.
  }

  return { isDailyQuota, retryDelayMs };
}
