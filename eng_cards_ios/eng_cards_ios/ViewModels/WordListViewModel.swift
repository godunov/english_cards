//
//  WordListViewModel.swift
//  eng_cards_ios
//

import Foundation
import Combine

class WordListViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var searchText: String = ""
    @Published var progressDict: [Int: WordProgress] = [:]
    @Published var selectedGroup: String? = nil
    @Published var newGroupName: String = ""
    
    private let dataService = DataService.shared
    private let progressService = ProgressService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Список всех доступных групп
    var availableGroups: [String] {
        return progressService.getAllGroups()
    }
    
    var filteredWords: [Word] {
        if searchText.isEmpty {
            return words
        }
        let lowercased = searchText.lowercased()
        return words.filter {
            $0.word.lowercased().contains(lowercased) ||
            $0.translation.lowercased().contains(lowercased)
        }
    }
    
    init() {
        loadWords()
        
        // Подписываемся на изменения прогресса
        progressService.$progressDict
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressDict = progress
            }
            .store(in: &cancellables)
    }
    
    func loadWords() {
        words = dataService.loadWords()
        progressDict = progressService.progressDict
    }
    
    func isLearning(wordId: Int) -> Bool {
        return progressService.isLearning(wordId: wordId)
    }
    
    func toggleLearning(wordId: Int) {
        let currentState = isLearning(wordId: wordId)
        progressService.setLearning(wordId: wordId, isLearning: !currentState, group: selectedGroup)
    }
    
    func setLearning(wordId: Int, isLearning: Bool) {
        progressService.setLearning(wordId: wordId, isLearning: isLearning, group: selectedGroup)
    }
    
    /// Добавляет новую группу и выбирает её
    func addGroup(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        selectedGroup = trimmedName
        newGroupName = ""
    }
    
    /// Перемещает слова в указанную группу
    func moveWordsToGroup(wordIds: [Int], group: String) {
        for wordId in wordIds {
            progressService.setGroup(wordId: wordId, group: group)
        }
    }
    
    /// Получает текущую группу слова
    func getGroup(wordId: Int) -> String? {
        return progressService.getGroup(wordId: wordId)
    }
}
