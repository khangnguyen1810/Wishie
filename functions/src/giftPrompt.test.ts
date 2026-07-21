import test from "node:test";
import assert from "node:assert/strict";
import { buildPrompt, parseGeminiJson } from "./giftPrompt.js";

test("buildPrompt includes interests, age, and avoid list", () => {
  const prompt = buildPrompt({
    interests: ["Gaming", "Reading"],
    age: 26,
    existingItemNames: ["AirPods"],
  });
  assert.match(prompt, /Gaming/);
  assert.match(prompt, /Reading/);
  assert.match(prompt, /26/);
  assert.match(prompt, /AirPods/);
  assert.match(prompt, /8|8-10|8 to 10/);
});

test("buildPrompt omits age line when age is null", () => {
  const prompt = buildPrompt({
    interests: ["Gaming"],
    age: null,
    existingItemNames: [],
  });
  assert.doesNotMatch(prompt, /age/i);
});

test("parseGeminiJson extracts ideas from a fenced code block", () => {
  const text =
    '```json\n{"ideas":[{"name":"KB","description":"d","price":"$1","link":"https://x/1"}]}\n```';
  const parsed = parseGeminiJson(text);
  assert.equal(parsed.ideas.length, 1);
  assert.equal(parsed.ideas[0].name, "KB");
});

test("parseGeminiJson extracts ideas from raw JSON", () => {
  const parsed = parseGeminiJson(
    '{"ideas":[{"name":"A","description":"d","price":"$1","link":"https://x/a"}]}',
  );
  assert.equal(parsed.ideas[0].link, "https://x/a");
});

test("parseGeminiJson throws on unparseable text", () => {
  assert.throws(() => parseGeminiJson("sorry, no json here"));
});

test("buildPrompt includes country line when country is provided", () => {
  const prompt = buildPrompt({
    interests: ["Gaming"],
    age: 26,
    existingItemNames: [],
    country: "Vietnam",
  });
  assert.match(prompt, /Vietnam/);
  assert.match(prompt, /located in Vietnam/i);
});

test("buildPrompt omits country line when country is null", () => {
  const prompt = buildPrompt({
    interests: ["Gaming"],
    age: 26,
    existingItemNames: [],
    country: null,
  });
  assert.doesNotMatch(prompt, /located in/i);
});
