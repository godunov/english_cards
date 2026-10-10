//
//  DataService.swift
//  eng_cards_ios
//

import Foundation

class DataService {
    static let shared = DataService()
    
    private var cachedWords: [Word]?
    
    private init() {}
    
    /// Загружает все слова из words.json
    func loadWords() -> [Word] {
        if let cached = cachedWords {
            return cached
        }
        
        // Пробуем найти файл в Media folder reference
        var url = Bundle.main.url(forResource: "words", withExtension: "json", subdirectory: "Media")
        
        // Если не найден, пробуем в корне bundle
        if url == nil {
            url = Bundle.main.url(forResource: "words", withExtension: "json")
        }
        
        guard let fileURL = url else {
            print("Ошибка: words.json не найден в bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let response = try JSONDecoder().decode(WordsResponse.self, from: data)
            cachedWords = response.words
            print("Загружено \(response.words.count) слов")
            return response.words
        } catch {
            print("Ошибка декодирования words.json: \(error)")
            return []
        }
    }
    
    /// Получает слово по ID
    func getWord(byId id: Int) -> Word? {
        return loadWords().first { $0.id == id }
    }
    
    /// Получает URL изображения для слова
    func getImageURL(for word: Word) -> URL? {
        guard !word.imagePath.isEmpty else { return nil }
        
        let fileName = word.imageFileName
        
        // Пробуем в Media/images
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Media/images") {
            return url
        }
        
        // Пробуем в images
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "images") {
            return url
        }
        
        // Пробуем без расширения
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        if let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: "jpg", subdirectory: "Media/images") {
            return url
        }
        
        return nil
    }
    
    /// Получает URL аудио для слова
    func getAudioURL(for word: Word) -> URL? {
        let fileName = word.audioFileName
        
        // Пробуем в Media/audio
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Media/audio") {
            return url
        }
        
        // Пробуем в audio
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "audio") {
            return url
        }
        
        // Пробуем без расширения
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        if let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: "mp3", subdirectory: "Media/audio") {
            return url
        }
        
        return nil
    }
}
