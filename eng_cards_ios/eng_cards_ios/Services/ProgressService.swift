//
//  ProgressService.swift
//  eng_cards_ios
//

import Foundation

class ProgressService: ObservableObject {
    static let shared = ProgressService()
    static let noGroupName = "Без группы"
    
    private let userDefaultsKey = "wordProgress"
    
    @Published private(set) var progressDict: [Int: WordProgress] = [:]
    
    private init() {
        loadProgress()
    }
    
    /// Загружает прогресс из UserDefaults
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            progressDict = [:]
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([Int: WordProgress].self, from: data)
            progressDict = decoded
        } catch {
            print("Ошибка загрузки прогресса: \(error)")
            progressDict = [:]
        }
    }
    
    /// Сохраняет прогресс в UserDefaults
    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(progressDict)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Ошибка сохранения прогресса: \(error)")
        }
    }
    
    /// Проверяет, изучается ли слово
    func isLearning(wordId: Int) -> Bool {
        return progressDict[wordId]?.isLearning ?? false
    }
    
    /// Получает категорию слова
    func getCategory(wordId: Int) -> Category? {
        return progressDict[wordId]?.category
    }
    
    /// Включает/выключает изучение слова
    func setLearning(wordId: Int, isLearning: Bool, group: String? = nil) {
        if isLearning {
            // Включаем изучение - добавляем в категорию "Не могу вспомнить"
            progressDict[wordId] = WordProgress(
                wordId: wordId,
                isLearning: true,
                category: .cannotRemember,
                group: group
            )
        } else {
            // Выключаем изучение - убираем из всех категорий
            progressDict[wordId] = WordProgress(
                wordId: wordId,
                isLearning: false,
                category: nil,
                group: nil
            )
        }
        saveProgress()
    }
    
    /// Перемещает слово в указанную категорию
    func moveToCategory(wordId: Int, category: Category) {
        if var progress = progressDict[wordId] {
            progress.category = category
            progress.isLearning = true
            progressDict[wordId] = progress
        } else {
            progressDict[wordId] = WordProgress(
                wordId: wordId,
                isLearning: true,
                category: category
            )
        }
        saveProgress()
    }
    
    /// Получает все слова в указанной категории
    func getWordIds(in category: Category) -> [Int] {
        return progressDict
            .filter { $0.value.isLearning && $0.value.category == category }
            .map { $0.key }
    }
    
    /// Получает количество слов в категории
    func getWordCount(in category: Category) -> Int {
        return getWordIds(in: category).count
    }
    
    /// Получает общее количество изучаемых слов
    func getTotalLearningCount() -> Int {
        return progressDict.filter { $0.value.isLearning }.count
    }
    
    // MARK: - Группы
    
    /// Проверяет, является ли слово "без группы"
    private func isNoGroup(_ group: String?) -> Bool {
        return group == nil || group?.isEmpty == true
    }
    
    /// Получает все уникальные группы
    func getAllGroups() -> [String] {
        let groups = progressDict.values
            .compactMap { $0.group }
            .filter { !$0.isEmpty }
        var result = Array(Set(groups)).sorted()
        
        // Добавляем "Без группы" в начало, если есть изучаемые слова без группы
        let hasWordsWithoutGroup = progressDict.values.contains { 
            $0.isLearning && isNoGroup($0.group) 
        }
        if hasWordsWithoutGroup {
            result.insert(Self.noGroupName, at: 0)
        }
        
        return result
    }
    
    /// Устанавливает группу для слова
    func setGroup(wordId: Int, group: String) {
        if var progress = progressDict[wordId] {
            progress.group = group
            progressDict[wordId] = progress
        } else {
            progressDict[wordId] = WordProgress(
                wordId: wordId,
                isLearning: false,
                category: nil,
                group: group
            )
        }
        saveProgress()
    }
    
    /// Получает все слова в указанной группе
    func getWordIds(inGroup group: String) -> [Int] {
        if group == Self.noGroupName {
            return progressDict
                .filter { isNoGroup($0.value.group) }
                .map { $0.key }
        }
        return progressDict
            .filter { $0.value.group == group }
            .map { $0.key }
    }
    
    /// Получает группу слова
    func getGroup(wordId: Int) -> String? {
        return progressDict[wordId]?.group
    }
    
    /// Получает слова в группе и категории
    func getWordIds(inGroup group: String, category: Category) -> [Int] {
        if group == Self.noGroupName {
            return progressDict
                .filter { $0.value.isLearning && isNoGroup($0.value.group) && $0.value.category == category }
                .map { $0.key }
        }
        return progressDict
            .filter { $0.value.isLearning && $0.value.group == group && $0.value.category == category }
            .map { $0.key }
    }
    
    /// Получает количество слов в группе и категории
    func getWordCount(inGroup group: String, category: Category) -> Int {
        return getWordIds(inGroup: group, category: category).count
    }
    
    /// Получает общее количество изучаемых слов в группе
    func getWordCount(inGroup group: String) -> Int {
        if group == Self.noGroupName {
            return progressDict
                .filter { $0.value.isLearning && isNoGroup($0.value.group) }
                .count
        }
        return progressDict
            .filter { $0.value.isLearning && $0.value.group == group }
            .count
    }
}
