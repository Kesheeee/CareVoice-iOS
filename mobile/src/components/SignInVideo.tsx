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
    if (reducedMotion || failed) {
      return;
    }
    void video.current?.play().catch(() => setFailed(true));
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
