import { useEffect, useRef, useState } from "react";

export function SignInVideo() {
  const video = useRef<HTMLVideoElement>(null);
  const [reducedMotion, setReducedMotion] = useState(() => window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setReducedMotion(query.matches);
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, []);
  useEffect(() => {
    const element = video.current;
    if (!element || reducedMotion || failed) return;
    let resumeTimer: ReturnType<typeof setTimeout> | undefined;
    const resume = () => {
      if (document.hidden) return;
      // A temporary autoplay block or interruption is not a broken video.
      // Keep the poster and retry when the page returns or the user taps.
      void element.play().catch(() => {});
    };
    const restart = () => { element.currentTime = 0; resume(); };
    const interrupted = () => {
      clearTimeout(resumeTimer);
      if (!document.hidden) resumeTimer = setTimeout(resume, 200);
    };
    const visibility = () => { if (document.hidden) element.pause(); else resume(); };
    element.addEventListener("canplay", resume);
    element.addEventListener("ended", restart);
    element.addEventListener("pause", interrupted);
    document.addEventListener("visibilitychange", visibility);
    document.addEventListener("pointerdown", resume);
    window.addEventListener("pageshow", resume);
    resume();
    return () => {
      element.removeEventListener("canplay", resume);
      element.removeEventListener("ended", restart);
      element.removeEventListener("pause", interrupted);
      clearTimeout(resumeTimer);
      document.removeEventListener("visibilitychange", visibility);
      document.removeEventListener("pointerdown", resume);
      window.removeEventListener("pageshow", resume);
      element.pause();
    };
  }, [reducedMotion, failed]);
  return (
    <div className="sign-in-video">
      {reducedMotion || failed ? (
        <img src="/media/carevoice-family-hd.jpg" alt="" width="720" height="1280" />
      ) : (
        <>
          <video ref={video} src="/media/carevoice-family-hd.mp4"
            poster="/media/carevoice-family-hd.jpg" autoPlay muted loop playsInline preload="auto"
            width="720" height="1280" aria-hidden="true" tabIndex={-1}
            onError={() => setFailed(true)} />
        </>
      )}
    </div>
  );
}
