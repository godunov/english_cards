//
//  AudioService.swift
//  eng_cards_ios
//

import Foundation
import AVFoundation

class AudioService: ObservableObject {
    static let shared = AudioService()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        // Настраиваем аудио сессию для воспроизведения
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудио сессии: \(error)")
        }
    }
    
    /// Воспроизводит аудио для указанного слова
    func play(word: Word) {
        guard let url = DataService.shared.getAudioURL(for: word) else {
            print("Аудио файл не найден для слова: \(word.word)")
            return
        }
        
        play(url: url)
    }
    
    /// Воспроизводит аудио по URL
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Ошибка воспроизведения аудио: \(error)")
        }
    }
    
    /// Останавливает воспроизведение
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    /// Проверяет, воспроизводится ли аудио
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}
