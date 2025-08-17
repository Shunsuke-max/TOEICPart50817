import AVFoundation

/// 効果音とBGMの再生を管理するクラス
class SoundManager {
    
    static let shared = SoundManager()
    private var effectPlayer: AVAudioPlayer? // 効果音用
    private var bgmPlayer: AVAudioPlayer? // BGM用

    /// 指定された名前のサウンドファイルを再生する
    /// - Parameter soundFileName: プロジェクトに追加したサウンドファイル名 (例: "correct.wav")
    func playSound(named soundFileName: String) {
        print("--- 🔊 SoundManager: playSound(\(soundFileName)) called ---")

        // 1. 設定を確認
        guard SettingsManager.shared.areSoundEffectsEnabled else {
            print("🔇 効果音設定がOFFのため再生をスキップしました。")
            return
        }
        print("✅ 効果音設定はONです。")

        // 2. ファイルのURLを取得
        guard let url = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            print("❌サウンドファイルが見つかりません: \(soundFileName)。プロジェクトにファイルが追加され、ターゲットに含まれているか確認してください。")
            return
        }
        print("✅ ファイルURLを取得しました: \(url.path)")

        // 3. プレイヤーを初期化して再生
        do {
            // セッションのカテゴリを設定して、他の音と共存できるようにする
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            effectPlayer = try AVAudioPlayer(contentsOf: url)
            print("✅ AVAudioPlayerの初期化に成功しました。")
            
            effectPlayer?.prepareToPlay()
            let isPlayed = effectPlayer?.play()
            
            if isPlayed == true {
                print("▶️ 効果音の再生を開始しました: \(soundFileName)")
            } else {
                print("⚠️ 効果音の再生に失敗しました (play()がfalseを返しました)。")
            }
        } catch {
            print("❌効果音の再生準備中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    /// 指定されたBGMファイルをループ再生する
    /// - Parameter bgmFileName: プロジェクトに追加したBGMファイル名 (例: "background_music.mp3")
    func playBGM(named bgmFileName: String) {
        // 設定がOFFなら再生しない
        guard SettingsManager.shared.isBGMEnabled else { return }
        
        // 既に再生中なら何もしない
        if bgmPlayer?.isPlaying == true { return }

        guard let url = Bundle.main.url(forResource: bgmFileName, withExtension: nil) else {
            print("❌BGMファイルが見つかりません: \(bgmFileName)")
            return
        }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // 無限ループ
            bgmPlayer?.volume = 0.5 // デフォルト音量
            bgmPlayer?.play()
            print("✅ BGM再生開始: \(bgmFileName)")
        } catch {
            print("❌BGMの再生に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// BGMの再生を停止する
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        print("✅ BGM停止")
    }
    
    /// BGMの再生を一時停止する
    func pauseBGM() {
        bgmPlayer?.pause()
        print("✅ BGM一時停止")
    }
    
    /// 一時停止したBGMの再生を再開する
    func resumeBGM() {
        // 設定がOFFなら再生しない
        guard SettingsManager.shared.isBGMEnabled else { return }
        bgmPlayer?.play()
        print("✅ BGM再開")
    }
}
