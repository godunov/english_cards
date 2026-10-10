//
//  WordListView.swift
//  eng_cards_ios
//

import SwiftUI

struct WordListView: View {
    @StateObject private var viewModel = WordListViewModel()
    @State private var showingAddGroupAlert = false
    
    // Режим множественного выбора
    @State private var isSelectionMode = false
    @State private var selectedWordIds: Set<Int> = []
    
    // Sheet для смены группы
    @State private var showingGroupSheet = false
    @State private var wordIdForGroupChange: Int? = nil  // nil = массовый перенос
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Выбор группы
                GroupPickerView(
                    selectedGroup: $viewModel.selectedGroup,
                    availableGroups: viewModel.availableGroups,
                    onAddGroup: { showingAddGroupAlert = true }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.selectedGroup != nil {
                    // Поиск
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Статистика и режим выбора
                    HStack {
                        if isSelectionMode {
                            Text("Выбрано: \(selectedWordIds.count)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        } else {
                            Text("Изучается: \(ProgressService.shared.getTotalLearningCount()) слов")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Список слов
                    List {
                        ForEach(isSelectionMode
                                ? viewModel.filteredWords.filter { viewModel.isLearning(wordId: $0.id) }
                                : viewModel.filteredWords) { word in
                            HStack(spacing: 0) {
                                // Чекбокс в режиме выбора
                                if isSelectionMode {
                                    Button(action: {
                                        toggleSelection(wordId: word.id)
                                    }) {
                                        Image(systemName: selectedWordIds.contains(word.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(selectedWordIds.contains(word.id) ? .blue : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing, 12)
                                }
                                
                                WordRowView(
                                    word: word,
                                    isLearning: viewModel.isLearning(wordId: word.id),
                                    currentGroup: viewModel.getGroup(wordId: word.id),
                                    isSelectionMode: isSelectionMode,
                                    onToggle: { isOn in
                                        viewModel.setLearning(wordId: word.id, isLearning: isOn)
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isSelectionMode {
                                        toggleSelection(wordId: word.id)
                                    }
                                }
                            }
                            .contextMenu {
                                // Контекстное меню для смены группы (только для изучаемых слов)
                                if viewModel.isLearning(wordId: word.id) {
                                    Button {
                                        wordIdForGroupChange = word.id
                                        showingGroupSheet = true
                                    } label: {
                                        Label("Переместить в группу...", systemImage: "folder")
                                    }
                                    
                                    if !viewModel.availableGroups.isEmpty {
                                        Divider()
                                        
                                        ForEach(viewModel.availableGroups.filter { $0 != viewModel.getGroup(wordId: word.id) }, id: \.self) { group in
                                            Button {
                                                viewModel.moveWordsToGroup(wordIds: [word.id], group: group)
                                            } label: {
                                                Label(group, systemImage: "folder")
                                            }
                                        }
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
                            .alignmentGuide(.listRowSeparatorLeading) { _ in -8 }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                    Text("Выберите группу для просмотра слов")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Слова")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.selectedGroup != nil {
                        if isSelectionMode {
                            HStack(spacing: 16) {
                                if !selectedWordIds.isEmpty {
                                    Button {
                                        wordIdForGroupChange = nil
                                        showingGroupSheet = true
                                    } label: {
                                        Image(systemName: "folder.badge.plus")
                                    }
                                }
                                
                                Button("Готово") {
                                    isSelectionMode = false
                                    selectedWordIds.removeAll()
                                }
                            }
                        } else {
                            Button("Выбрать") {
                                isSelectionMode = true
                            }
                        }
                    }
                }
            }
            .alert("Новая группа", isPresented: $showingAddGroupAlert) {
                TextField("Название группы", text: $viewModel.newGroupName)
                Button("Отмена", role: .cancel) {
                    viewModel.newGroupName = ""
                }
                Button("Добавить") {
                    viewModel.addGroup(name: viewModel.newGroupName)
                }
            } message: {
                Text("Введите название новой группы")
            }
            .sheet(isPresented: $showingGroupSheet) {
                GroupSelectionSheet(
                    availableGroups: viewModel.availableGroups,
                    onSelectGroup: { group in
                        if let wordId = wordIdForGroupChange {
                            // Одиночный перенос
                            viewModel.moveWordsToGroup(wordIds: [wordId], group: group)
                        } else {
                            // Массовый перенос
                            viewModel.moveWordsToGroup(wordIds: Array(selectedWordIds), group: group)
                            selectedWordIds.removeAll()
                            isSelectionMode = false
                        }
                        showingGroupSheet = false
                    },
                    onCreateGroup: { newGroup in
                        if let wordId = wordIdForGroupChange {
                            viewModel.moveWordsToGroup(wordIds: [wordId], group: newGroup)
                        } else {
                            viewModel.moveWordsToGroup(wordIds: Array(selectedWordIds), group: newGroup)
                            selectedWordIds.removeAll()
                            isSelectionMode = false
                        }
                        showingGroupSheet = false
                    }
                )
            }
        }
    }
    
    private func toggleSelection(wordId: Int) {
        if selectedWordIds.contains(wordId) {
            selectedWordIds.remove(wordId)
        } else {
            selectedWordIds.insert(wordId)
        }
    }
}

struct GroupPickerView: View {
    @Binding var selectedGroup: String?
    let availableGroups: [String]
    let onAddGroup: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Button("Выберите группу") {
                    selectedGroup = nil
                }
                
                if !availableGroups.isEmpty {
                    Divider()
                    
                    ForEach(availableGroups, id: \.self) { group in
                        Button(group) {
                            selectedGroup = group
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedGroup ?? "Выберите группу")
                        .foregroundColor(selectedGroup == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Button(action: onAddGroup) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct WordRowView: View {
    let word: Word
    let isLearning: Bool
    let currentGroup: String?
    let isSelectionMode: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            // Номер слова
            Text("\(word.id)")
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 36, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.translation)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(word.word)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    if !word.transcription.isEmpty {
                        Text("/\(word.transcription)/")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Иконка звука
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.6))
                    
                    // Показываем группу, если она есть
                    if let group = currentGroup, !group.isEmpty {
                        Text(group)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }
            .onTapGesture {
                if !isSelectionMode {
                    AudioService.shared.play(word: word)
                }
            }
            
            Spacer()
            
            if !isSelectionMode {
                Toggle("", isOn: Binding(
                    get: { isLearning },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .tint(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - GroupSelectionSheet

struct GroupSelectionSheet: View {
    let availableGroups: [String]
    let onSelectGroup: (String) -> Void
    let onCreateGroup: (String) -> Void
    
    @State private var newGroupName = ""
    @State private var showingNewGroupField = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Существующие группы
                Section {
                    ForEach(availableGroups, id: \.self) { group in
                        Button {
                            onSelectGroup(group)
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(group)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                } header: {
                    if !availableGroups.isEmpty {
                        Text("Существующие группы")
                    }
                }
                
                // Создание новой группы
                Section {
                    if showingNewGroupField {
                        HStack {
                            TextField("Название группы", text: $newGroupName)
                                .textFieldStyle(.plain)
                            
                            Button("Создать") {
                                let trimmed = newGroupName.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                onCreateGroup(trimmed)
                            }
                            .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else {
                        Button {
                            showingNewGroupField = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Создать новую группу")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } header: {
                    Text("Новая группа")
                }
            }
            .navigationTitle("Выберите группу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Поиск слова...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    WordListView()
}
