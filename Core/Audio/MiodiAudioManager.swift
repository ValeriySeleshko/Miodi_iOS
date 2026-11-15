//
//  MiodiAudioManager.swift
//  Plan4U_iOS
//
//  Audio effects player matching Android AppFeedbackManager.
//

import Foundation
import AVFoundation

public final class MiodiAudioManager {
    public static let shared = MiodiAudioManager()

    private var player: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    public func playRustle() {
        playSound(named: "rustle", ext: "wav")
    }

    public func playPurr() {
        playSound(named: "purr", ext: "wav")
    }

    public func playDing() {
        playSound(named: "ding", ext: "wav")
    }

    public func playBubble() {
        let index = Int.random(in: 1...5)
        playSound(named: "bubble\(index)", ext: "wav")
    }

    public func playTabClick() {
        playSound(named: "tab", ext: "wav")
    }

    public func playWheelTick() {
        playSound(named: "wheel_tick", ext: "wav")
    }

    public func playTriumphFanfare() {
        // Look for triumph or fanfare first, fallback to ding or system sound
        if let url = Bundle.main.url(forResource: "triumph", withExtension: "wav") ??
                     Bundle.main.url(forResource: "fanfare", withExtension: "wav") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
                return
            } catch {}
        }
        playDing()
        AudioServicesPlaySystemSound(1025) // Fanfare/chime sound ID
    }

    private func playSound(named name: String, ext: String) {
        // Look in main bundle or Resources subfolder
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) ??
                        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") else {
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Audio playback is non-fatal
        }
    }
}
