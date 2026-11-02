import test from "node:test";
import assert from "node:assert/strict";
import { classifyProviderError } from "./index.js";

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
