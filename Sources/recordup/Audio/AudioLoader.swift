import Foundation
import WhisperKit

enum AudioLoader {
    /// `.m4a` 등 임의의 오디오를 16kHz mono Float32 PCM 배열로 로드한다.
    /// WhisperKit·SpeakerKit이 같은 배열을 공유해 변환을 두 번 하지 않게 한다.
    static func loadFloatArray(from url: URL) throws -> [Float] {
        try AudioProcessor.loadAudioAsFloatArray(
            fromPath: url.path,
            channelMode: .sumChannels(nil)
        )
    }
}
