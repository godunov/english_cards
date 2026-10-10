//
//  WordProgress.swift
//  eng_cards_ios
//

import Foundation

struct WordProgress: Codable {
    let wordId: Int
    var isLearning: Bool
    var category: Category?
    var group: String?
    
    init(wordId: Int, isLearning: Bool = false, category: Category? = nil, group: String? = nil) {
        self.wordId = wordId
        self.isLearning = isLearning
        self.category = category
        self.group = group
    }
}
