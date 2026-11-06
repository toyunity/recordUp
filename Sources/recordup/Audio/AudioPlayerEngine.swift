import AVFoundation
import Combine
import Foundation

/// 전사본 검토 등에서 원본 음성을 재생하기 위한 단순 엔진.
/// AVAudioPlayer + 폴링 타이머로 playhead/isPlaying을 published한다.
@MainActor
final class AudioPlayerEngine: ObservableObject {
    @Published private(set) var playhead: TimeInterval = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var loadedURL: URL?
    private var timer: Timer?

    deinit {
        timer?.invalidate()
        player?.stop()
    }

    /// 같은 URL이면 재로드를 스킵한다.
    func load(url: URL) {
        if let loaded = loadedURL, loaded == url, player != nil { return }
        stopTimer()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            player = p
            loadedURL = url
            duration = p.duration
            playhead = 0
            isPlaying = false
        } catch {
            DebugLog.log("[audio] AudioPlayerEngine.load failed for \(url.lastPathComponent): \(error)")
            player = nil
            loadedURL = nil
            duration = 0
            playhead = 0
            isPlaying = false
        }
    }

    func play() {
        guard let p = player else { return }
        if p.currentTime >= max(0, p.duration - 0.05) {
            p.currentTime = 0
        }
        p.play()
        isPlaying = p.isPlaying
        startTimer()
    }

    func pause() {
        guard let p = player else { return }
        p.pause()
        isPlaying = false
        playhead = p.currentTime
        stopTimer()
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    /// 절대 시간으로 seek. 재생 상태는 보존한다.
    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        let clamped = max(0, min(p.duration, time))
        p.currentTime = clamped
        playhead = clamped
    }

    /// 상대 seek (예: -10초 / +10초).
    func seek(by delta: TimeInterval) {
        seek(to: playhead + delta)
    }

    /// 특정 시간으로 이동 + 재생 시작.
    func playFrom(_ time: TimeInterval) {
        seek(to: time)
        play()
    }

    func restart() {
        seek(to: 0)
        if isPlaying { pause() }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard let p = self.player else { return }
                self.playhead = p.currentTime
                if !p.isPlaying {
                    self.isPlaying = false
                    self.stopTimer()
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
