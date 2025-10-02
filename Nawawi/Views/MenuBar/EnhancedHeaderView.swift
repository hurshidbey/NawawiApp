//
//  EnhancedHeaderView.swift
//  Nawawi
//
//  MenuBar header component with search and language selection
//  Extracted from MenuBarView for better modularity
//

import SwiftUI

struct EnhancedHeaderView: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    @Binding var showingFavoritesOnly: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var notificationManager: NotificationManager

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // App icon with animation
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse, isActive: notificationManager.hasActiveReminder)

                // Book selector menu
                Menu {
                    ForEach(HadithBook.allCases) { book in
                        Button(action: {
                            withAnimation {
                                dataManager.loadHadiths(book: book)
                                appState.currentHadithIndex = 0
                            }
                        }) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.displayName)
                                        .font(.nohemiCaption)
                                    Text(book.arabicName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: dataManager.currentBook == book ? "checkmark.circle.fill" : book.icon)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: dataManager.currentBook.icon)
                            .font(.caption)
                        Text(dataManager.currentBook.shortName)
                            .font(.nohemiCaption)
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.nawawi_softCream.opacity(0.5))
                    )
                }
                .menuStyle(.borderlessButton)

                // Language selector with flags
                Menu {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            withAnimation {
                                appState.selectedLanguage = language
                            }
                        }) {
                            Label {
                                HStack {
                                    Text(language.displayName)
                                        .font(.nohemiCaption)
                                    if appState.selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                            } icon: {
                                Text(language.flag)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(appState.selectedLanguage.flag)
                            .font(.title3)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                }
                .menuStyle(.borderlessButton)

                Spacer()

                // Filter toggle
                Button(action: {
                    withAnimation {
                        showingFavoritesOnly.toggle()
                        appState.currentHadithIndex = 0
                    }
                }) {
                    Label("Favorites", systemImage: showingFavoritesOnly ? "heart.fill" : "heart")
                        .font(.nohemiButton)
                        .foregroundStyle(showingFavoritesOnly ? Color.nawawi_darkGreen : .black)
                        .symbolEffect(.bounce, value: showingFavoritesOnly)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("l", modifiers: [.command])
            }

            // Enhanced search bar
            SearchBar(
                text: $searchText,
                isFocused: isSearchFocused,
                placeholder: "Search hadiths...",
                onClear: {
                    appState.currentHadithIndex = 0
                }
            )
            .keyboardShortcut("f", modifiers: [.command])
        }
        .padding()
        .nawawi_creamGlass()
        .nawawi_subtleShadow()
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
