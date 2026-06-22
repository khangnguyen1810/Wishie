# Clarification Questions Template

## Purpose

Record questions raised during planning and their confirmed answers to resolve ambiguities in task requirements, ensuring the implementation plan reflects verified decisions.

# Guide:

- NEVER add question's options into this file, keep context small.
- ONLY add questions and it's answer following the template below.

# Template

```
- [the question]:
[the answer and its brief reasoning]
```

# Clarification Questions:

- After WKWebView fires didFinishNavigation, how long should the app wait before executing the metadata extraction JavaScript?
  2 seconds — balances rendering completeness against user wait time.

- What is the maximum total time the WKWebView fetch should wait before aborting with an error?
  20 seconds — consistent with network timeouts for slow connections.

- Which domains should trigger the WKWebView extraction path?
  All e-commerce platforms (Shopee, Lazada, Amazon, and more). This drives the architectural decision to replace the URLSession path entirely with a unified WKWebView approach for all URLs, eliminating per-domain detection logic.

- If WKWebView extracts a product title but image or price is missing, what should happen?
  Show partial result — the name alone is sufficient to add the item. Partial data is not treated as a failure.

- If WKWebView navigation fails for a product URL, should the app fall back to the existing URLSession HTML-parsing approach?
  No fallback — surface an error immediately. The URLSession path would not succeed for JS-rendered pages anyway.
