export interface GiftPromptInput {
  interests: string[];
  age: number | null;
  existingItemNames: string[];
}

export interface GiftIdea {
  name: string;
  description: string;
  price: string;
  link: string;
}

export interface GiftIdeas {
  ideas: GiftIdea[];
}

export function buildPrompt(input: GiftPromptInput): string {
  const { interests, age, existingItemNames } = input;
  const interestLine = `The person enjoys: ${interests.join(", ")}.`;
  const ageLine =
    typeof age === "number" ? `They are about ${age} years old.` : "";
  const avoidLine =
    existingItemNames && existingItemNames.length
      ? `Do NOT suggest anything similar to items they already have: ${existingItemNames.join(", ")}.`
      : "";

  return [
    "You are a thoughtful gift-recommendation assistant.",
    interestLine,
    ageLine,
    avoidLine,
    "Suggest 8 to 10 specific, real, purchasable gift products that fit these interests.",
    'For each gift provide: a short product name, a one-sentence description, an estimated price (e.g. "$25"), and a direct https product link to a real, currently-buyable item on a major store.',
    "Prefer links to well-known retailers. Every link must be a real, working https URL to a specific product listing.",
    'Respond with ONLY valid JSON in exactly this shape: {"ideas":[{"name":"","description":"","price":"","link":""}]}',
    "Do not include any prose outside the JSON.",
  ]
    .filter(Boolean)
    .join("\n");
}

export function parseGeminiJson(text: string): GiftIdeas {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1] : text;
  const start = candidate.indexOf("{");
  const end = candidate.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error("No JSON object found in model response");
  }
  const json = JSON.parse(candidate.slice(start, end + 1));
  if (!json || !Array.isArray(json.ideas)) {
    throw new Error("Parsed JSON has no ideas array");
  }
  return json as GiftIdeas;
}
