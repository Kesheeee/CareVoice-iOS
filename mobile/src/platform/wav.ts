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

export async function validateAudioUpload(file: File): Promise<void> {
  const ext = file.name.split(".").pop()?.toLowerCase();
  if (!ext || !["mp3", "m4a", "wav", "aac", "flac"].includes(ext)
    || (file.type && !file.type.startsWith("audio/") && file.type !== "application/octet-stream")) {
    throw new AudioFileError("file-type");
  }
  if (file.size > 20 * 1024 * 1024) throw new AudioFileError("file-size");
  const bytes = new Uint8Array(await file.arrayBuffer());
  const text = (a: number, b: number) => new TextDecoder().decode(bytes.subarray(a, b));
  const view = new DataView(bytes.buffer);
  let valid = false;
  if (ext === "wav") valid = text(0, 4) === "RIFF" && text(8, 12) === "WAVE";
  if (ext === "flac") valid = text(0, 4) === "fLaC";
  if (ext === "mp3") valid = text(0, 3) === "ID3" || (bytes[0] === 255 && (bytes[1] & 224) === 224);
  if (ext === "aac") valid = bytes[0] === 255 && (bytes[1] & 246) === 240;
  if (ext === "m4a") {
    let audio = false, video = false, malformed = false;
    const walk = (start: number, end: number, depth: number) => {
      if (depth > 8) { malformed = true; return; }
      let i = start;
      while (i + 8 <= end) {
        let size = view.getUint32(i), header = 8;
        const kind = text(i + 4, i + 8);
        if (size === 1) {
          if (i + 16 > end) { malformed = true; return; }
          size = Number(view.getBigUint64(i + 8)); header = 16;
        } else if (size === 0) size = end - i;
        if (size < header || i + size > end) { malformed = true; return; }
        if (["moov", "trak", "mdia"].includes(kind)) walk(i + header, i + size, depth + 1);
        if (kind === "hdlr" && size >= header + 12) {
          const handler = text(i + header + 8, i + header + 12);
          audio ||= handler === "soun"; video ||= handler === "vide";
        }
        i += size;
      }
      if (i !== end) malformed = true;
    };
    if (text(4, 8) === "ftyp") walk(0, bytes.length, 0);
    valid = audio && !video && !malformed;
  }
  if (!valid) throw new AudioFileError("file-type");
}

export async function recordingToWav(audio: Blob, uploaded = false): Promise<Blob> {
  if (!audio.size) throw new AudioFileError("file-format");
  if (audio.size > 20 * 1024 * 1024) throw new AudioFileError("file-size");
  if (uploaded) await validateAudioUpload(audio as File);
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
