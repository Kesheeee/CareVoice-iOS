export function encodeWav(samples: Float32Array): ArrayBuffer {
  const length = Math.min(samples.length, 960000);
  const buffer = new ArrayBuffer(44 + length * 2), view = new DataView(buffer);
  const label = (offset: number, value: string) => [...value].forEach((c, i) => view.setUint8(offset + i, c.charCodeAt(0)));
  label(0, "RIFF"); view.setUint32(4, buffer.byteLength - 8, true); label(8, "WAVE");
  label(12, "fmt "); view.setUint32(16, 16, true); view.setUint16(20, 1, true);
  view.setUint16(22, 1, true); view.setUint32(24, 16000, true); view.setUint32(28, 32000, true);
  view.setUint16(32, 2, true); view.setUint16(34, 16, true);
  label(36, "data"); view.setUint32(40, length * 2, true);
  for (let i = 0; i < length; i++) {
    const sample = Math.max(-1, Math.min(1, samples[i]));
    view.setInt16(44 + i * 2, sample < 0 ? sample * 32768 : sample * 32767, true);
  }
  return buffer;
}

export class AudioFileError extends Error {
  code: string;
  constructor(code: string) { super(code); this.code = code; }
}

export async function recordingToWav(audio: Blob, uploaded = false): Promise<Blob> {
  if (!audio.size) throw new AudioFileError("file-format");
  if (audio.size > 20 * 1024 * 1024) throw new AudioFileError("file-size");
  const context = new AudioContext();
  try {
    let decoded: AudioBuffer;
    try { decoded = await context.decodeAudioData(await audio.arrayBuffer()); }
    catch { throw new AudioFileError("file-format"); }
    if (uploaded && decoded.duration > 60) throw new AudioFileError("file-duration");
    const frames = Math.min(Math.ceil(decoded.duration * 16000), 960000);
    if (!frames) throw new Error("Empty recording");
    const offline = new OfflineAudioContext(1, frames, 16000);
    const source = offline.createBufferSource();
    source.buffer = decoded; source.connect(offline.destination); source.start();
    const rendered = await offline.startRendering();
    return new Blob([encodeWav(rendered.getChannelData(0))], { type: "audio/wav" });
  } finally { await context.close(); }
}
