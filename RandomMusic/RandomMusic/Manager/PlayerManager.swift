import AVFoundation

/// AVPlayer 기반의 오디오 재생을 관리하는 클래스입니다.
///
/// 이 클래스는 AVURLAsset을 통해 스트리밍 오디오를 재생하고,
/// 재생 시간 갱신 및 재생 종료에 대한 콜백을 제공합니다.
final class PlayerManager {
    static let shared = PlayerManager()

    // 네트워크 호출을 PlayerManager에서 하고
    // trackList 보관을 PlayerManager
    // play, pause, 다음곡 재생, 이전곡 재생 -> PlayerManager.shared.play()

    // MARK: - 변경점 Start
    private(set) var trackList: [SongModel] = [] // 플레이리스트를 여기서 보관
    private(set) var currentIndex: Int = 0 // 재생되고 있는 인덱스 보관
    // MARK: - 변경점 End
    private(set) var player: AVPlayer?

    /// 한 곡 반복 재생 여부를 설정합니다.
    var isRepeatEnabled = false

    /// 플레이어가 초기화되었는지 여부를 나타냅니다.
    var isPlayerReady: Bool {
        return player != nil
    }

    /// 재생 시간이 주기적으로 업데이트될 때 호출되는 클로저입니다.
    var onTimeUpdate: ((Double) -> Void)?

    /// 현재 재생 항목이 끝까지 재생되었을 때 호출되는 클로저입니다.
    var onPlaybackFinished: (() -> Void)?


    private var timeObserverToken: Any?

    // MARK: - 변경점 Start
    func play() {
        // 네트워크를 여기서 직접 호출
        let asset = NetworkManager.shared.createAssetWithHeaders(url: trackList[currentIndex].streamUrl)
        let item = AVPlayerItem(asset: asset!)
        player = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            if self.isRepeatEnabled {
                self.seek(to: 0)
                self.player?.play()
            } else {
                self.onPlaybackFinished?()
            }
        }

        addPeriodicTimeObserver()
        player?.play()
    }

    /// 다음 곡 재생
    func nextTrack() {
        currentIndex += 1
        Task {
            do {
                let songModel = try await NetworkManager.shared.getMusic()
                DataManager.shared.insertSongData(from: songModel)
                trackList.append(songModel)
                play()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    /// 이전 곡 재생
    func beforeTrack() {
        currentIndex -= 1
        play()
    }

    /// 플레이리스트 트랙 저장
    func setTrackList(_ trackList: [SongModel]) {
        self.trackList = trackList
    }

    /// 마지막으로 들었었던 트랙 인덱스 불러오기. (아마 UserDefaults로 저장해야 함.)
    func setCurrentIndex(_ indexPath: IndexPath) {
        self.currentIndex = indexPath.row
    }

    // MARK: - 변경점 End

    /// 현재 오디오 재생을 일시정지합니다.
    func pause() {
        player?.pause()
    }

    /// 일시정지된 오디오 재생을 다시 시작합니다.
    func resume() {
        player?.play()
    }

    /// 재생 위치를 지정한 시간으로 이동합니다.
    ///
    /// - Parameter seconds: 이동할 시간(초)입니다.
    func seek(to seconds: Float64) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
    }

    /// AVURLAsset의 전체 재생 시간을 비동기적으로 로드합니다.
    ///
    /// - Parameters:
    ///   - asset: 재생 시간 정보를 가져올 AVURLAsset입니다.
    ///   - completion: 재생 시간이 성공적으로 로드되면 호출되는 클로저입니다. 실패 시 nil이 전달됩니다.
    func loadDuration(with asset: AVURLAsset, completion: @escaping (Double?) -> Void) {
        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)

                DispatchQueue.main.async {
                    completion(seconds.isFinite ? seconds : nil)
                }
            } catch {
                print("Duration load error: ", error)

                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    /// 재생 시간 정보를 주기적으로 업데이트합니다.
    private func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            let seconds = CMTimeGetSeconds(time)

            self?.onTimeUpdate?(seconds)
        }
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }

        NotificationCenter.default.removeObserver(self)
    }
}
