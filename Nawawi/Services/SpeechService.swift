//
//  SpeechService.swift
//  Nawawi
//
//  Centralized text-to-speech service using AVSpeechSynthesizer
//  Replaces deprecated NSSpeechSynthesizer and eliminates duplicate code
//

import Foundation
import AVFoundation
import Combine

@MainActor
class SpeechService: ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SpeechDelegate?

    init() {
        self.delegate = SpeechDelegate(service: self)
        synthesizer.delegate = delegate
    }

    // MARK: - Public Methods

    /// Speak text in specified language
    /// - Parameters:
    ///   - text: Text to speak
    ///   - languageCode: BCP 47 language code (e.g., "ar-SA", "en-US", "uz-UZ")
    func speak(_ text: String, languageCode: String) {
        // Stop any ongoing speech
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5 // Slightly slower for better clarity

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Speak text with automatic language detection
    func speak(_ text: String) {
        speak(text, languageCode: detectLanguage(from: text))
    }

    /// Stop current speech
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }

    /// Pause current speech
    func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// Resume paused speech
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    // MARK: - Private Helpers

    /// Detect language from text (simple heuristic)
    private func detectLanguage(from text: String) -> String {
        // Check for Arabic characters
        if text.range(of: "\\p{Arabic}", options: .regularExpression) != nil {
            return "ar-SA"
        }
        // Default to English
        return "en-US"
    }

    // MARK: - Delegate

    private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
        weak var service: SpeechService?

        init(service: SpeechService) {
            self.service = service
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            Task { @MainActor in
                service?.isSpeaking = false
            }
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            Task { @MainActor in
                service?.isSpeaking = false
            }
        }
    }
}

// MARK: - Language Code Helpers

extension SpeechService {
    /// Get language code from AppLanguage enum
    static func languageCode(for language: AppLanguage) -> String {
        switch language {
        case .arabic:
            return "ar-SA"
        case .english:
            return "en-US"
        case .uzbek:
            return "uz-UZ"
        }
    }
}
