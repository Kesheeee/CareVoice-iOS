import { test } from "node:test";
import assert from "node:assert/strict";
import { encodeWav } from "../src/platform/wav.ts";
import { createHandler, validWav } from "../../supabase/functions/transcribe/handler.ts";

const audio = () => new Uint8Array(encodeWav(new Float32Array([0, -1, 1, 0.5])));
const request = (body = audio(), token = "test-token", language = "en-US") => new Request("https://example.test/transcribe", {
  method: "POST", headers: { authorization: `Bearer ${token}`, "content-type": "audio/wav", "x-speech-language": language }, body,
});
const neverFetch = async () => { throw new Error("Provider must not be called"); };
const base = { authenticate: async (token: string) => token === "test-token", key: "test-key", region: "eastasia", fetch: neverFetch };

test("WAV encoding preserves signed PCM and enforces the 60 second limit", () => {
  const bytes = audio(); assert.equal(validWav(bytes), true);
  const view = new DataView(bytes.buffer);
  assert.equal(view.getInt16(46, true), -32768); assert.equal(view.getInt16(48, true), 32767);
  assert.equal(encodeWav(new Float32Array(960010)).byteLength, 1920044);
  bytes[24] = 0; assert.equal(validWav(bytes), false);
});
test("rejects unauthenticated requests before speech processing", async () => {
  assert.equal((await createHandler(base)(request(audio(), "invalid"))).status, 401);
});
test("rejects malformed, oversized and unsupported-language recordings", async () => {
  const handler = createHandler(base);
  assert.equal((await handler(request(new Uint8Array(44)))).status, 400);
  assert.equal((await handler(request(new Uint8Array(1920045)))).status, 413);
  assert.equal((await handler(request(audio(), "test-token", "invalid"))).status, 400);
});
test("reports absent speech configuration without exposing credentials", async () => {
  const response = await createHandler({ ...base, key: undefined })(request());
  assert.equal(response.status, 503); assert.deepEqual(await response.json(), { code: "unconfigured" });
});
test("forwards validated audio and language and returns only the transcript", async () => {
  let calls = 0;
  const handler = createHandler({ ...base, fetch: async (url, options) => {
    calls++; assert.match(String(url), /language=zh-HK/);
    assert.equal(new Headers(options?.headers).get("Ocp-Apim-Subscription-Key"), "test-key");
    assert.deepEqual(options?.body, audio());
    return Response.json({ RecognitionStatus: "Success", DisplayText: "A calm day.", private: "omit" });
  }});
  const response = await handler(request(audio(), "test-token", "zh-HK"));
  assert.equal(calls, 1); assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { text: "A calm day.", language: "zh-HK", status: "Success" });
});
test("normalises provider errors and supports CORS preflight", async () => {
  const handler = createHandler({ ...base, fetch: async () => new Response("private provider error", { status: 429 }) });
  const response = await handler(request());
  assert.equal(response.status, 429); assert.deepEqual(await response.json(), { code: "rate-limit" });
  assert.equal((await handler(new Request("https://example.test", { method: "OPTIONS" }))).status, 204);
});
