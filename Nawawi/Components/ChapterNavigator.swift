//
//  ChapterNavigator.swift
//  Nawawi
//
//  Chapter navigation sidebar for browsing hadiths by thematic chapters
//

import SwiftUI

struct ChapterNavigator: View {
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var appState: AppState
    @Binding var isVisible: Bool
    @Binding var selectedHadithIndex: Int?
    @Binding var filterByChapterId: Int?
    let filteredHadiths: [Hadith]
    @State private var searchText = ""

    // Callback to clear search text when navigating to chapter
    let onChapterSelected: () -> Void

    // Get unique chapters from current book
    private var chapters: [ChapterGroup] {
        var chapterDict: [Int: ChapterGroup] = [:]

        for hadith in dataManager.hadiths {
            if let chapter = hadith.chapter, let chapterId = hadith.chapterId {
                if chapterDict[chapterId] == nil {
                    chapterDict[chapterId] = ChapterGroup(
                        id: chapterId,
                        title: chapter.title,
                        arabicTitle: chapter.arabicTitle,
                        hadithCount: 0,
                        firstHadithNumber: hadith.number
                    )
                }
                chapterDict[chapterId]?.hadithCount += 1
            }
        }

        return chapterDict.values.sorted { $0.id < $1.id }
    }

    private var filteredChapters: [ChapterGroup] {
        if searchText.isEmpty {
            return chapters
        }
        return chapters.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicTitle.contains(searchText)
        }
    }

    // Get current chapter based on currently displayed hadith in filtered list
    private var currentChapterId: Int? {
        guard !filteredHadiths.isEmpty else { return nil }
        guard let selectedIndex = selectedHadithIndex else { return nil }
        let safeIndex = min(max(0, selectedIndex), filteredHadiths.count - 1)
        return filteredHadiths[safeIndex].chapterId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "book.pages.fill")
                    .font(.title2)
                    .foregroundStyle(Color.nawawi_darkGreen)

                Text("Chapters")
                    .font(.nohemiTitle)
                    .foregroundColor(.black)

                Spacer()

                Button(action: { withAnimation { isVisible = false } }) {
                    Image(systemName: "sidebar.left")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.nawawi_softCream)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search chapters...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.nohemiBody)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.nawawi_cream.opacity(0.5))
            )
            .padding()

            // Chapter list
            if chapters.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No chapters available")
                        .font(.nohemiBody)
                        .foregroundStyle(.secondary)

                    Text("\(dataManager.currentBook.displayName) does not contain chapter divisions.\n\nChapter navigation is available for books like Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, and Ibn Majah.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredChapters) { chapter in
                            ChapterRow(
                                chapter: chapter,
                                isSelected: chapter.id == currentChapterId,
                                action: {
                                    withAnimation {
                                        // Clear search filter when selecting chapter
                                        onChapterSelected()

                                        // Set chapter filter to show only this chapter's hadiths
                                        filterByChapterId = chapter.id

                                        // Select first hadith in this chapter by finding its number
                                        // Find first hadith with this chapter ID in the full list
                                        if let firstHadithInChapter = dataManager.hadiths.first(where: { $0.chapterId == chapter.id }) {
                                            // Find this hadith's index in the full list
                                            if let indexInFullList = dataManager.hadiths.firstIndex(where: { $0.number == firstHadithInChapter.number }) {
                                                appState.currentHadithIndex = indexInFullList
                                            }
                                        }

                                        // Set filtered list index to 0 (first in filtered results)
                                        selectedHadithIndex = 0
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }

            // Footer stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(chapters.count) Chapters")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    Text("\(dataManager.hadiths.count) Total Hadiths")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(dataManager.currentBook.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.nawawi_softCream)
        }
        .frame(width: 320)
        .background(Color.nawawi_background)
        .overlay(
            Rectangle()
                .fill(Color.nawawi_darkGreen.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Chapter Group Model
struct ChapterGroup: Identifiable {
    let id: Int
    let title: String
    let arabicTitle: String
    var hadithCount: Int
    let firstHadithNumber: Int
}

// MARK: - Chapter Row Component
struct ChapterRow: View {
    let chapter: ChapterGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Chapter number badge
                Text("\(chapter.id)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : Color.nawawi_darkGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.nawawi_darkGreen : Color.nawawi_cream)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    // English title
                    Text(chapter.title)
                        .font(.nohemiBody)
                        .foregroundColor(isSelected ? .black : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Arabic title
                    Text(chapter.arabicTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    // Hadith count
                    Text("\(chapter.hadithCount) hadiths")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.nawawi_darkGreen)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.nawawi_softCream : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.nawawi_darkGreen.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
