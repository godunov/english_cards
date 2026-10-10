//
//  FlashCardView.swift
//  eng_cards_ios
//

import SwiftUI

struct FlashCardView: View {
    let word: Word
    let isShowingAnswer: Bool
    let studyMode: StudyMode
    let isEnglishHidden: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isShowingAnswer {
                // Показываем ответ
                if studyMode == .direct {
                    answerView
                } else {
                    reverseAnswerView
                }
            } else {
                // Показываем вопрос
                if studyMode == .direct {
                    questionView
                } else {
                    reverseQuestionView
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            onTap()
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(word.translation)
                .font(.title)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if !word.examples.isEmpty {
                examplesView(showRussian: true)
            }
            
            Spacer()
            
            Text("Нажмите, чтобы увидеть ответ")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }
    
    private var answerView: some View {
        VStack(spacing: 16) {
            // Изображение
            if let imageURL = DataService.shared.getImageURL(for: word),
               let imageData = try? Data(contentsOf: imageURL),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
                    .cornerRadius(12)
                    .padding(.top, 20)
            } else {
                // Placeholder если нет изображения
                Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                    .frame(height: 70)
                    .padding(.top, 20)
            }
            
            // Английское слово
            if isEnglishHidden {
                Text("• • •")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            } else {
                Text(word.word)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Транскрипция
            if !word.transcription.isEmpty {
                Text("/\(word.transcription)/")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            if !word.examples.isEmpty {
                examplesView(showRussian: false)
            }
            
            Spacer()
            
            Text("Нажмите для следующей карточки")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Reverse Mode Views
    
    private var reverseQuestionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if isEnglishHidden {
                Text("• • •")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            } else {
                Text(word.word)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if !word.transcription.isEmpty {
                Text("/\(word.transcription)/")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            if !word.examples.isEmpty {
                examplesView(showRussian: false)
            }
            
            Spacer()
            
            Text("Вспомните перевод")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }
    
    private var reverseAnswerView: some View {
        VStack(spacing: 16) {
            // Изображение
            if let imageURL = DataService.shared.getImageURL(for: word),
               let imageData = try? Data(contentsOf: imageURL),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
                    .cornerRadius(12)
                    .padding(.top, 20)
            } else {
                // Placeholder если нет изображения
                Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                    .frame(height: 70)
                    .padding(.top, 20)
            }
            
            // Русский перевод (главный акцент)
            Text(word.translation)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Английское слово (для справки)
            if isEnglishHidden {
                Text("• • •")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text(word.word)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Транскрипция
            if !word.transcription.isEmpty {
                Text("/\(word.transcription)/")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !word.examples.isEmpty {
                examplesView(showRussian: true)
            }
            
            Spacer()
            
            Text("Нажмите для следующей карточки")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Examples View
    
    private func examplesView(showRussian: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(word.examples.enumerated()), id: \.offset) { _, example in
                    Text(showRussian ? example.translation : example.sentence)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxHeight: 280)
    }
}

#Preview {
    VStack {
        FlashCardView(
            word: Word(
                id: 1,
                word: "hello",
                translation: "привет",
                transcription: "həˈləʊ",
                imagePath: "",
                audioPath: "",
                examples: [
                    Example(sentence: "Hello, how are you?", translation: "Привет, как дела?"),
                    Example(sentence: "She said hello to everyone.", translation: "Она поздоровалась со всеми.")
                ]
            ),
            isShowingAnswer: false,
            studyMode: .direct,
            isEnglishHidden: false,
            onTap: {}
        )
        .frame(height: 400)
        .padding()
    }
}
