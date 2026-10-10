//
//  StudyViewModel.swift
//  eng_cards_ios
//

import Foundation
import Combine

class StudyViewModel: ObservableObject {
    @Published var currentCategory: Category
    @Published var words: [Word] = []
    @Published var currentIndex: Int = 0
    @Published var isShowingAnswer: Bool = false
    @Published var selectedCategoryForCurrentWord: Category? = nil  // Категория текущего слова
    @Published var elapsedTime: Int = 0  // Прошедшее время в секундах
    @Published var studyMode: StudyMode = .direct  // Режим изучения
    @Published var isBatchMode: Bool = false  // Режим батчей (по 5 слов) или все слова
    @Published var currentBatchIndex: Int = 0  // Текущий батч (0-based)
    let batchSize = 5  // Размер батча
    let group: String  // Группа для изучения
    private var allShuffledWords: [Word] = []  // Полный перемешанный список слов
    private var displayedWord: Word? = nil  // Сохраняем текущее отображаемое слово
    private var timerStartTime: Date? = nil  // Время начала показа вопроса
    private var timer: Timer? = nil  // Таймер для отслеживания времени
    
    private let dataService = DataService.shared
    private let progressService = ProgressService.shared
    private let audioService = AudioService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentWord: Word? {
        // Если есть сохраненное слово для отображения, показываем его
        if let displayed = displayedWord {
            return displayed
        }
        // Иначе показываем слово из списка по текущему индексу
        guard currentIndex >= 0 && currentIndex < words.count else {
            return nil
        }
        return words[currentIndex]
    }
    
    var hasWords: Bool {
        return !words.isEmpty
    }
    
    var progress: String {
        guard hasWords else { return "0/0" }
        return "\(currentIndex + 1)/\(words.count)"
    }
    
    // MARK: - Batch properties
    
    var totalBatches: Int {
        guard !allShuffledWords.isEmpty else { return 0 }
        return (allShuffledWords.count + batchSize - 1) / batchSize
    }
    
    var batchProgress: String {
        guard totalBatches > 0 else { return "" }
        return "Группа \(currentBatchIndex + 1) из \(totalBatches)"
    }
    
    var canGoToNextBatch: Bool {
        return currentBatchIndex < totalBatches - 1
    }
    
    var canGoToPreviousBatch: Bool {
        return currentBatchIndex > 0
    }
    
    init(category: Category, group: String) {
        self.currentCategory = category
        self.group = group
        loadWords()
        
        // Убираем автоматическую подписку на изменения прогресса
        // Это предотвращает автоматическое перемешивание списка при изменении категории слова
        // Слова перезагружаются только при явном вызове loadWords()
    }
    
    deinit {
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()  // Останавливаем предыдущий таймер, если он был
        elapsedTime = 0
        timerStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.timerStartTime else { return }
            let elapsed = Int(Date().timeIntervalSince(startTime))
            DispatchQueue.main.async {
                self.elapsedTime = elapsed
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerStartTime = nil
    }
    
    func loadWords() {
        let wordIds = progressService.getWordIds(inGroup: group, category: currentCategory)
        let allWords = dataService.loadWords()
        
        allShuffledWords = wordIds.compactMap { id in
            allWords.first { $0.id == id }
        }
        allShuffledWords.shuffle()  // Перемешиваем слова в случайном порядке
        
        currentBatchIndex = 0
        
        if isBatchMode {
            loadCurrentBatch()
        } else {
            words = allShuffledWords
            currentIndex = 0
            isShowingAnswer = false
            selectedCategoryForCurrentWord = nil
            
            if !words.isEmpty {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    // MARK: - Batch methods
    
    private func loadCurrentBatch() {
        let start = currentBatchIndex * batchSize
        let end = min(start + batchSize, allShuffledWords.count)
        
        if start < allShuffledWords.count {
            words = Array(allShuffledWords[start..<end])
        } else {
            words = []
        }
        
        currentIndex = 0
        isShowingAnswer = false
        selectedCategoryForCurrentWord = nil
        displayedWord = nil
        
        if !words.isEmpty {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    func nextBatch() {
        guard canGoToNextBatch else { return }
        currentBatchIndex += 1
        loadCurrentBatch()
    }
    
    func previousBatch() {
        guard canGoToPreviousBatch else { return }
        currentBatchIndex -= 1
        loadCurrentBatch()
    }
    
    func toggleBatchMode() {
        isBatchMode.toggle()
        
        if isBatchMode {
            // Переключаемся в батч-режим
            loadCurrentBatch()
        } else {
            // Переключаемся в режим "все слова"
            words = allShuffledWords
            currentIndex = 0
            isShowingAnswer = false
            selectedCategoryForCurrentWord = nil
            displayedWord = nil
            
            if !words.isEmpty {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    func showAnswer() {
        isShowingAnswer = true
        // Останавливаем таймер при показе ответа
        stopTimer()
        
        // При показе ответа устанавливаем текущую категорию слова (если еще не была выбрана)
        if selectedCategoryForCurrentWord == nil {
            if let word = currentWord {
                selectedCategoryForCurrentWord = progressService.getCategory(wordId: word.id) ?? currentCategory
            }
        }
        if let word = currentWord {
            audioService.play(word: word)
        }
    }
    
    func nextCard() {
        // Очищаем сохраненное слово при переходе к следующей карточке
        displayedWord = nil
        // Сбрасываем выбранную категорию при переходе к следующей карточке
        selectedCategoryForCurrentWord = nil
        
        if currentIndex < words.count - 1 {
            currentIndex += 1
        } else {
            // Круг завершен - перемешиваем и начинаем заново
            words.shuffle()
            currentIndex = 0
        }
        isShowingAnswer = false
        // Запускаем таймер для нового вопроса
        startTimer()
        // Категория будет установлена при показе ответа (в showAnswer)
    }
    
    func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            isShowingAnswer = false
            // Запускаем таймер для нового вопроса
            startTimer()
        }
    }
    
    func cardTapped() {
        // Если есть сохраненное слово (после удаления из списка), переходим к следующему
        if displayedWord != nil {
            displayedWord = nil
            selectedCategoryForCurrentWord = nil
            // Корректируем индекс, если нужно
            if !words.isEmpty && currentIndex >= words.count {
                currentIndex = words.count - 1
            }
            // Показываем следующее слово в режиме вопроса
            isShowingAnswer = false
            // Запускаем таймер для нового вопроса
            startTimer()
            return
        }
        
        if isShowingAnswer {
            nextCard()
        } else {
            showAnswer()
        }
    }
    
    func moveCurrentWordToCategory(_ category: Category) {
        // Получаем текущее отображаемое слово
        let word: Word
        if let displayed = displayedWord {
            word = displayed
        } else if currentIndex >= 0 && currentIndex < words.count {
            word = words[currentIndex]
        } else {
            return
        }
        
        progressService.moveToCategory(wordId: word.id, category: category)
        
        // Обновляем выбранную категорию для текущего слова
        selectedCategoryForCurrentWord = category
        
        // Если слово переместилось в другую категорию, удаляем его из текущего списка
        if category != currentCategory {
            // Сохраняем текущее слово для отображения
            displayedWord = word
            
            // Запоминаем текущий индекс перед удалением
            let removedIndex = currentIndex
            
            // Удаляем слово из текущего списка и из полного списка
            words.removeAll { $0.id == word.id }
            allShuffledWords.removeAll { $0.id == word.id }
            
            // Корректируем индекс после удаления
            if words.isEmpty {
                currentIndex = 0
            } else if removedIndex >= words.count {
                // Если удалили слово с индексом >= длины нового списка, переходим на последнее
                currentIndex = words.count - 1
            }
            // Если удалили слово не в конце списка, остаемся на том же индексе
            // Теперь на этом индексе будет следующее слово, но мы показываем сохраненное
            
            // НЕ сбрасываем isShowingAnswer - оставляем текущее состояние карточки
            // Слово остается видимым, переход к следующему произойдет только при клике на карточку
        }
        
        // НЕ переходим к следующему слову автоматически
        // Переход произойдет только при клике на карточку (когда isShowingAnswer == true)
    }
    
    func playAudio() {
        if let word = currentWord {
            audioService.play(word: word)
        }
    }
    
    func toggleStudyMode() {
        studyMode = (studyMode == .direct) ? .reverse : .direct
    }
    
    /// Получает количество слов в указанной категории для текущей группы
    func wordCount(for category: Category) -> Int {
        return progressService.getWordCount(inGroup: group, category: category)
    }
    
    /// Список всех групп, кроме текущей
    var availableGroups: [String] {
        return progressService.getAllGroups().filter { $0 != group }
    }
    
    /// Перемещает текущее слово в другую группу
    func moveCurrentWordToGroup(_ newGroup: String) {
        // Получаем текущее отображаемое слово
        let word: Word
        if let displayed = displayedWord {
            word = displayed
        } else if currentIndex >= 0 && currentIndex < words.count {
            word = words[currentIndex]
        } else {
            return
        }
        
        progressService.setGroup(wordId: word.id, group: newGroup)
        
        // Слово переместилось в другую группу — удаляем из текущего списка
        // Сохраняем текущее слово для отображения
        displayedWord = word
        
        // Запоминаем текущий индекс перед удалением
        let removedIndex = currentIndex
        
        // Удаляем слово из текущего списка и из полного списка
        words.removeAll { $0.id == word.id }
        allShuffledWords.removeAll { $0.id == word.id }
        
        // Корректируем индекс после удаления
        if words.isEmpty {
            currentIndex = 0
        } else if removedIndex >= words.count {
            currentIndex = words.count - 1
        }
        
        // НЕ сбрасываем isShowingAnswer — слово остается видимым,
        // переход к следующему произойдет при клике на карточку
    }
}
