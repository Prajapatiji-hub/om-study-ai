import test from "node:test";
import assert from "node:assert/strict";
import Worker, { classifyProviderError } from "./index.js";

test("Gemini quota errors stay distinguishable", () => {
  const result = classifyProviderError(429, "RESOURCE_EXHAUSTED");
  assert.equal(result.error, "resource_exhausted");
  assert.equal(result.httpStatus, 429);
});

test("invalid API keys are diagnosed without exposing provider text", () => {
  const result = classifyProviderError(400, "API key not valid. Please pass a valid API key.");
  assert.equal(result.error, "invalid_api_key");
  assert.equal(result.httpStatus, 503);
  assert.equal(result.message.includes("Please pass"), false);
});

test("permission and model errors are distinguishable", () => {
  assert.equal(classifyProviderError(403).error, "provider_permission_denied");
  assert.equal(classifyProviderError(404).error, "model_not_found");
});

test("server failures receive a temporary-unavailability message", () => {
  const result = classifyProviderError(503, "internal server error");
  assert.equal(result.error, "provider_server_error");
  assert.equal(result.httpStatus, 503);
});

test("unexpected provider errors do not leak raw details", () => {
  const result = classifyProviderError(418, "sensitive internal provider detail");
  assert.equal(result.error, "provider_unavailable");
  assert.equal(result.message.includes("sensitive"), false);
});

import { checkUserRateLimit, isValidQuizResponse, readJsonRequest } from "./index.js";

test("rate limiter keys usage by authenticated UID and allows under-limit requests", async () => {
  let received;
  const result = await checkUserRateLimit({ limit: async (input) => { received = input; return { success: true }; } }, "student-123");
  assert.deepEqual(received, { key: "student-123" });
  assert.deepEqual(result, { allowed: true, configured: true });
});

test("rate limiter rejects exceeded limits and fails closed when unavailable", async () => {
  assert.deepEqual(await checkUserRateLimit({ limit: async () => ({ success: false }) }, "student-123"), { allowed: false, configured: true });
  assert.deepEqual(await checkUserRateLimit(null, "student-123"), { allowed: false, configured: false });
  assert.deepEqual(await checkUserRateLimit({ limit: async () => { throw new Error("offline"); } }, "student-123"), { allowed: false, configured: false });
});

test("request parser rejects oversized and malformed JSON bodies", async () => {
  assert.deepEqual(await readJsonRequest(new Request("https://example.test", { method: "POST", body: "12345" }), 4), { error: "request_too_large", status: 413 });
  assert.deepEqual(await readJsonRequest(new Request("https://example.test", { method: "POST", body: "{" })), { error: "invalid_json", status: 400 });
  assert.deepEqual(await readJsonRequest(new Request("https://example.test", { method: "POST", body: JSON.stringify({ message: "ok" }) })), { data: { message: "ok" } });
});

const validQuestion = () => ({ question: "2 + 2?", options: ["3", "4", "5", "6"], answerIndex: 1, explanation: "2 + 2 = 4", topic: "arithmetic" });
test("quiz schema accepts valid quizzes and rejects invalid counts, duplicate options and answer indexes", () => {
  assert.equal(isValidQuizResponse({ title: "Math", questions: [validQuestion(), validQuestion(), validQuestion()] }, 3), true);
  assert.equal(isValidQuizResponse({ title: "Math", questions: [validQuestion()] }, 3), false);
  const duplicate = validQuestion(); duplicate.options[3] = "3";
  assert.equal(isValidQuizResponse({ title: "Math", questions: [duplicate] }, 1), false);
  const invalidIndex = validQuestion(); invalidIndex.answerIndex = 4;
  assert.equal(isValidQuizResponse({ title: "Math", questions: [invalidIndex] }, 1), false);
  assert.equal(isValidQuizResponse({ title: " ", questions: [validQuestion()] }, 1), false);
});

test("Worker rejects requests with no Firebase bearer token", async () => {
  const response = await Worker.fetch(
    new Request("https://worker.example.test", { method: "POST", body: JSON.stringify({ message: "hello" }) }),
    { FIREBASE_PROJECT_ID: "test-project", GOOGLE_GENAI_API_KEY: "test-only" },
  );
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error, "unauthenticated");
});

test("Worker rejects malformed Firebase bearer tokens", async () => {
  const response = await Worker.fetch(
    new Request("https://worker.example.test", {
      method: "POST",
      headers: { Authorization: "Bearer not-a-valid-jwt" },
      body: JSON.stringify({ message: "hello" }),
    }),
    { FIREBASE_PROJECT_ID: "test-project", GOOGLE_GENAI_API_KEY: "test-only" },
  );
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error, "unauthenticated");
});

test("Worker handles OPTIONS and unsupported methods without authentication", async () => {
  const options = await Worker.fetch(new Request("https://worker.example.test", { method: "OPTIONS" }), {});
  const get = await Worker.fetch(new Request("https://worker.example.test", { method: "GET" }), {});
  assert.equal(options.status, 200);
  assert.equal(get.status, 405);
});
