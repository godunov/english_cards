//
//  StudySessionView.swift
//  eng_cards_ios
//

import SwiftUI

struct StudySessionView: View {
    @StateObject private var viewModel: StudyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEnglishHidden = false
    @State private var showingGroupSheet = false
    
    init(category: Category, group: String) {
        _viewModel = StateObject(wrappedValue: StudyViewModel(category: category, group: group))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasWords {
                // Прогресс, батч и категория
                HStack {
                    Text(viewModel.progress)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if viewModel.isBatchMode {
                        Text(viewModel.batchProgress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Переключатели режимов
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isBatchMode ? "rectangle.stack" : "square.grid.2x2")
                        Text(viewModel.isBatchMode ? "По 5 слов" : "Все слова")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                    .onTapGesture { viewModel.toggleBatchMode() }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text(viewModel.studyMode.title)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .onTapGesture { viewModel.toggleStudyMode() }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Навигация по батчам (только в батч-режиме)
                if viewModel.isBatchMode {
                    batchNavigationView
                        .padding(.top, 18)
                }
                
                // Карточка
                if let word = viewModel.currentWord {
                    FlashCardView(
                        word: word,
                        isShowingAnswer: viewModel.isShowingAnswer,
                        studyMode: viewModel.studyMode,
                        isEnglishHidden: isEnglishHidden,
                        onTap: { viewModel.cardTapped() }
                    )
                    .padding()
                }
                
                Spacer()
                
                // Кнопки категорий
                categoryButtonsView
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
            } else {
                emptyStateView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { isEnglishHidden.toggle() }) {
                    Image(systemName: isEnglishHidden ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(isEnglishHidden ? .secondary : .blue)
                }
                
                Button(action: { viewModel.playAudio() }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                }
                
                Button(action: { showingGroupSheet = true }) {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingGroupSheet) {
            GroupSelectionSheet(
                availableGroups: viewModel.availableGroups,
                onSelectGroup: { group in
                    viewModel.moveCurrentWordToGroup(group)
                    showingGroupSheet = false
                },
                onCreateGroup: { newGroup in
                    viewModel.moveCurrentWordToGroup(newGroup)
                    showingGroupSheet = false
                }
            )
        }
    }
    
    private var batchNavigationView: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.previousBatch() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Пред. 5")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .disabled(!viewModel.canGoToPreviousBatch)
            .opacity(viewModel.canGoToPreviousBatch ? 1.0 : 0.3)
            
            Spacer()
            
            Button(action: { viewModel.nextBatch() }) {
                HStack(spacing: 4) {
                    Text("След. 5")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .disabled(!viewModel.canGoToNextBatch)
            .opacity(viewModel.canGoToNextBatch ? 1.0 : 0.3)
        }
        .padding(.horizontal)
    }
    
    private var categoryButtonsView: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.elapsedTime) сек")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .monospacedDigit()
            
            HStack(spacing: 8) {
                ForEach(Category.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        wordCount: viewModel.wordCount(for: category),
                        isCurrentCategory: viewModel.selectedCategoryForCurrentWord == category || 
                                         (viewModel.selectedCategoryForCurrentWord == nil && category == viewModel.currentCategory),
                        isEnabled: true,
                        action: {
                            viewModel.moveCurrentWordToCategory(category)
                        }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Нет слов в этой категории")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Добавьте слова для изучения\nна вкладке \"Слова\"")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Назад") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct CategoryButton: View {
    let category: Category
    let wordCount: Int
    let isCurrentCategory: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: category.icon)
                        .font(.title3)
                    
                    Text("\(wordCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                
                Text(category.shortTitle)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCurrentCategory ? colorForCategory(category).opacity(0.3) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCurrentCategory ? colorForCategory(category) : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isEnabled ? colorForCategory(category) : colorForCategory(category).opacity(0.4))
        }
        .disabled(!isEnabled)
    }
    
    private func colorForCategory(_ category: Category) -> Color {
        switch category {
        case .cannotRemember:
            return .red
        case .hardToRemember:
            return .orange
        case .canRemember:
            return .yellow
        case .easyToRemember:
            return .green
        case .automaticRemember:
            return .blue
        }
    }
}

#Preview {
    NavigationView {
        StudySessionView(category: .cannotRemember, group: "Test")
    }
}
