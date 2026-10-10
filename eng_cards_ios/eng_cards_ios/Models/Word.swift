//
//  Word.swift
//  eng_cards_ios
//

import Foundation

struct Example: Codable {
    let sentence: String
    let translation: String
}

struct WordsResponse: Codable {
    let words: [Word]
}

struct Word: Codable, Identifiable {
    let id: Int
    let word: String
    let translation: String
    let transcription: String
    let imagePath: String
    let audioPath: String
    let examples: [Example]
    
    enum CodingKeys: String, CodingKey {
        case id
        case word
        case translation
        case transcription
        case imagePath = "image_path"
        case audioPath = "audio_path"
        case examples
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        word = try container.decode(String.self, forKey: .word)
        translation = try container.decode(String.self, forKey: .translation)
        transcription = try container.decode(String.self, forKey: .transcription)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        audioPath = try container.decode(String.self, forKey: .audioPath)
        examples = try container.decodeIfPresent([Example].self, forKey: .examples) ?? []
    }
    
    init(id: Int, word: String, translation: String, transcription: String, imagePath: String, audioPath: String, examples: [Example] = []) {
        self.id = id
        self.word = word
        self.translation = translation
        self.transcription = transcription
        self.imagePath = imagePath
        self.audioPath = audioPath
        self.examples = examples
    }
    
    /// Возвращает имя файла изображения (без пути)
    var imageFileName: String {
        // image_path имеет формат "images/1_the.jpg"
        return imagePath.components(separatedBy: "/").last ?? ""
    }
    
    /// Возвращает имя аудио файла (формируем из id и word)
    var audioFileName: String {
        return "\(id)_\(word).mp3"
    }
}
