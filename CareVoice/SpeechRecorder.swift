import AVFoundation
import Speech
import SwiftUI

@MainActor
final class SpeechRecorder: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isStarting = false
    @Published var seconds = 0
    @Published var error: String?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Task<Void, Never>?
    private var tapInstalled = false
    private var generation = UUID()

    func start(language: AppLanguage) async {
        guard !isRecording && !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        error = nil
        let sessionID = UUID(); generation = sessionID
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language == .english ? "en-US" : "zh-HK")), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            error = language.text("On-device speech recognition is unavailable for this language on this device. Please type your observation.", "此裝置暫不支援這個語言的裝置端語音辨識，請使用文字輸入。")
            return
        }
        let speechStatus = await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) } }
        guard speechStatus == .authorized else {
            error = language.text("Speech access is off. You can enable it in Settings or type instead.", "語音辨識權限未開啟，可於設定啟用，或改用文字輸入。")
            return
        }
        guard generation == sessionID else { return }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard microphone else {
            error = language.text("Microphone access is off. You can enable it in Settings or type instead.", "咪高峰權限未開啟，可於設定啟用，或改用文字輸入。")
            return
        }
        guard !Task.isCancelled, generation == sessionID else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            self.request = request
            let node = engine.inputNode
            let format = node.outputFormat(forBus: 0)
            guard format.sampleRate > 0 && format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            transcript = ""; seconds = 0
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, failure in
                let text = result?.bestTranscription.formattedString
                let finished = result?.isFinal == true
                Task { @MainActor [weak self] in
                    guard let self, self.generation == sessionID else { return }
                    if let text { self.transcript = text }
                    if finished || failure != nil {
                        if failure != nil && self.transcript.isEmpty { self.error = language.text("No speech was recognised. Please try again or type your observation.", "未能辨識語音，請再試或使用文字輸入。") }
                        self.stop()
                    }
                }
            }
            engine.prepare(); try engine.start(); isRecording = true
            timer = Task { [weak self] in
                for second in 1...60 {
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                    guard let self, self.isRecording else { return }
                    self.seconds = second
                }
                self?.stop()
            }
        } catch {
            stop()
            self.error = language.text("Recording could not start. Please try again or type your observation.", "未能開始錄音，請再試或使用文字輸入。")
        }
    }
    func stop() {
        generation = UUID()
        timer?.cancel(); timer = nil
        if engine.isRunning { engine.stop() }
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); recognitionTask?.cancel()
        request = nil; recognitionTask = nil; isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
