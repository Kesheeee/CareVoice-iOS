import test from "node:test";
import assert from "node:assert/strict";
import { VoiceSession, type SpeechEngine, type SpeechResult, type VoiceState } from "../src/platform/speech.ts";

class FakeSpeech implements SpeechEngine {
  lang = ""; continuous = false; interimResults = false; maxAlternatives = 0;
  onstart: SpeechEngine["onstart"] = null;
  onresult: SpeechEngine["onresult"] = null;
  onerror: SpeechEngine["onerror"] = null;
  onend: SpeechEngine["onend"] = null;
  starts = 0; stops = 0; aborts = 0;
  start() { this.starts++; }
  stop() { this.stops++; }
  abort() { this.aborts++; }
  result(...parts: [string, boolean][]) {
    const results: SpeechResult[] = parts.map(([transcript, isFinal]) => ({ isFinal, 0: { transcript } }));
    this.onresult?.({ results });
  }
}
function fixture() {
  const engine = new FakeSpeech();
  let state: VoiceState = { status: "idle", seconds: 0, interim: "" };
  const texts: string[] = [];
  const session = new VoiceSession(() => engine, next => { state = next; }, text => texts.push(text));
  return { engine, texts, session, state: () => state };
}

test("Only confirmed speech updates the draft; revised and repeated results do not duplicate words", () => {
  const f = fixture();
  try {
    f.session.start("zh-HK"); f.session.start("zh-HK");
    assert.equal(f.engine.starts, 1); assert.equal(f.engine.lang, "zh-HK");
    f.engine.onstart?.();
    f.engine.result(["Good", false]); f.engine.result(["Good morning", false]);
    assert.deepEqual(f.texts, []); assert.equal(f.state().interim, "Good morning");
    f.engine.result(["Good morning.", true]); f.engine.result(["Good morning.", true]);
    f.engine.result(["Good morning.", true], ["We went outside.", true]);
    assert.deepEqual(f.texts, ["Good morning.", "Good morning. We went outside."]);
  } finally { f.session.dispose(); }
});

test("Stop waits for the final transcript and then releases the microphone", () => {
  const f = fixture();
  f.session.start("en-US"); f.engine.onstart?.(); f.session.stop();
  assert.equal(f.state().status, "stopping"); assert.equal(f.engine.stops, 1);
  f.engine.result(["A completed note.", true]); f.engine.onend?.();
  assert.equal(f.state().status, "review"); assert.deepEqual(f.texts, ["A completed note."]);
  assert.equal(f.engine.aborts, 1); assert.equal(f.engine.onresult, null);
});

test("Permission denial preserves confirmed text and returns a retryable error", () => {
  const f = fixture();
  f.session.start("en-US"); f.engine.onstart?.(); f.engine.result(["Keep this.", true]);
  f.engine.onerror?.({ error: "not-allowed" });
  assert.equal(f.state().status, "error"); assert.equal(f.state().error, "permission");
  assert.deepEqual(f.texts, ["Keep this."]); assert.equal(f.engine.aborts, 1);
  f.session.start("en-US"); assert.equal(f.engine.starts, 2); f.session.dispose();
});

test("Cancel and unmount abort capture and ignore delayed provider events", () => {
  const f = fixture();
  f.session.start("en-US");
  const lateStart = f.engine.onstart, lateResult = f.engine.onresult;
  f.session.cancel(); lateStart?.();
  lateResult?.({ results: [{ isFinal: true, 0: { transcript: "Do not append" } }] });
  assert.equal(f.state().status, "idle"); assert.deepEqual(f.texts, []);
  f.session.start("en-US"); f.session.dispose(); assert.equal(f.engine.aborts, 2);
});

test("Recording stops after 60 seconds and a stalled finalisation releases capture", context => {
  context.mock.timers.enable({ apis: ["Date", "setTimeout", "setInterval"] });
  const f = fixture(); f.session.start("en-US"); f.engine.onstart?.();
  context.mock.timers.tick(60000);
  assert.equal(f.engine.stops, 1); assert.equal(f.state().seconds, 60); assert.equal(f.state().status, "stopping");
  context.mock.timers.tick(8000);
  assert.equal(f.state().error, "timeout"); assert.equal(f.engine.aborts, 1);
  f.session.dispose();
});

test("Unsupported browsers and speech-free sessions never report a successful recording", () => {
  let state: VoiceState | undefined;
  const unavailable = new VoiceSession(undefined, next => { state = next; }, () => assert.fail("Unexpected transcript"));
  unavailable.start("en-US"); assert.equal(state?.error, "unsupported");
  const f = fixture(); f.session.start("en-US"); f.engine.onstart?.(); f.engine.onend?.();
  assert.equal(f.state().error, "no-speech"); assert.deepEqual(f.texts, []);
});

test("A permission request that never resolves is cancelled after 30 seconds", context => {
  context.mock.timers.enable({ apis: ["setTimeout"] });
  const f = fixture(); f.session.start("en-US"); context.mock.timers.tick(30000);
  assert.equal(f.state().error, "timeout"); assert.equal(f.engine.aborts, 1);
  f.session.dispose();
});
