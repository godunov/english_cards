//
//  CategoryListView.swift
//  eng_cards_ios
//

import SwiftUI

// MARK: - Список групп (первый уровень навигации)

struct CategoryListView: View {
    @ObservedObject private var progressService = ProgressService.shared
    
    var body: some View {
        NavigationView {
            Group {
                if progressService.getAllGroups().isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(progressService.getAllGroups(), id: \.self) { group in
                            NavigationLink(destination: CategoryListForGroupView(group: group)) {
                                GroupRowView(
                                    groupName: group,
                                    wordCount: progressService.getWordCount(inGroup: group)
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Изучение")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Нет групп для изучения")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Создайте группу и добавьте слова\nна вкладке \"Слова\"")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Строка группы

struct GroupRowView: View {
    let groupName: String
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(groupName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text("\(wordCount) слов")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if wordCount > 0 {
                Text("\(wordCount)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Список категорий для группы (второй уровень навигации)

struct CategoryListForGroupView: View {
    let group: String
    @ObservedObject private var progressService = ProgressService.shared
    
    var body: some View {
        List {
            ForEach(Category.allCases, id: \.self) { category in
                NavigationLink(destination: StudySessionView(category: category, group: group)) {
                    CategoryRowView(
                        category: category,
                        wordCount: progressService.getWordCount(inGroup: group, category: category)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(group)
    }
}

struct CategoryRowView: View {
    let category: Category
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(colorForCategory(category))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text("\(wordCount) слов")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if wordCount > 0 {
                Text("\(wordCount)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorForCategory(category))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
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
    CategoryListView()
}
