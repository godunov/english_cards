//
//  Category.swift
//  eng_cards_ios
//

import Foundation

enum Category: Int, CaseIterable, Codable {
    case cannotRemember = 0      // Не могу вспомнить
    case hardToRemember = 1      // Могу вспомнить с трудом
    case canRemember = 2         // Могу вспомнить
    case easyToRemember = 3      // Легко вспоминаю
    case automaticRemember = 4   // Автоматически помню
    
    var title: String {
        switch self {
        case .cannotRemember:
            return "Не могу вспомнить"
        case .hardToRemember:
            return "Могу вспомнить с трудом"
        case .canRemember:
            return "Могу вспомнить"
        case .easyToRemember:
            return "Легко вспоминаю"
        case .automaticRemember:
            return "Автоматически помню"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .cannotRemember:
            return "Не помню"
        case .hardToRemember:
            return "С трудом"
        case .canRemember:
            return "Помню"
        case .easyToRemember:
            return "Легко"
        case .automaticRemember:
            return "Авто"
        }
    }
    
    var icon: String {
        switch self {
        case .cannotRemember:
            return "xmark.circle"
        case .hardToRemember:
            return "questionmark.circle"
        case .canRemember:
            return "checkmark.circle"
        case .easyToRemember:
            return "star.circle"
        case .automaticRemember:
            return "bolt.circle"
        }
    }
}

enum StudyMode: String, CaseIterable {
    case direct = "direct"      // Русский -> Английский
    case reverse = "reverse"    // Английский -> Русский
    
    var title: String {
        switch self {
        case .direct: return "RU → EN"
        case .reverse: return "EN → RU"
        }
    }
}
