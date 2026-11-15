//
//  PetCompanionView.swift
//  Plan4U_iOS
//
//  Interactive Maine Coon Cat Companion on the Notebook screen.
//  Reactions to petting: taps and swipes trigger purring vibration, haptics,
//  floating heart/sparkle particles, speech bubbles, and mood changes.
//

import SwiftUI
import SwiftData

private struct FloatingHeartParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let startX: CGFloat
    let startY: CGFloat
    var offsetX: CGFloat = 0.0
    var offsetY: CGFloat = 0.0
    var opacity: Double = 1.0
    var scale: CGFloat = 0.6
}

public struct PetCompanionView: View {
    @Bindable public var pet: PetItem
    public var onOpenModal: () -> Void

    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentQuote: String = ""
    @State private var showSpeechBubble: Bool = true
    @State private var isPurring: Bool = false
    @State private var isEating: Bool = false
    @State private var particles: [FloatingHeartParticle] = []
    @State private var bubbleDismissTimer: Task<Void, Never>? = nil

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(pet: PetItem, onOpenModal: @escaping () -> Void) {
        self.pet = pet
        self.onOpenModal = onOpenModal
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Floating Cat Speech Bubble
            if showSpeechBubble && !currentQuote.isEmpty {
                Button {
                    cycleCatQuote()
                    MiodiHapticFeedback.lightClick()
                } label: {
                    HStack(spacing: 6) {
                        Text(pet.mood.emoji)
                            .font(.system(size: 13))

                        Text(currentQuote)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(isDark ? Color(hex: 0xF1F5F9) : Color(hex: 0x1E293B))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isDark ? Color(hex: 0x1E2433).opacity(0.95) : Color(hex: 0xFFFBEB).opacity(0.96))
                            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.1), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isDark ? Color(hex: 0x384256) : Color(hex: 0xF97316).opacity(0.35),
                                lineWidth: 1.2
                            )
                    )
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }

            // Circular Mascot Button with 3D Pop-out Cat & Gestures
            ZStack {
                // Background Circle with shadow & accent border
                Circle()
                    .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xFFF7ED))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.15), radius: 6, x: 0, y: 3)
                    .overlay(
                        Circle()
                            .stroke(
                                isDark ? Color(hex: 0x384256) : Color(hex: 0xF97316),
                                lineWidth: 2
                            )
                    )

                // 3D pop-out Hand-Drawn Illustrated Maine Coon Cat Mascot
                MaineCoonIllustratedCatView(
                    colorScheme: pet.color,
                    isSleeping: pet.isSleeping,
                    isPurring: isPurring,
                    isEating: isEating
                )
                .frame(width: 72, height: 72)
                .offset(y: -7)

                // Mood Badge (e.g. 🐟 hungry or 💤 sleeping)
                if pet.mood == .hungry || pet.mood == .sleeping {
                    Text(pet.mood.emoji)
                        .font(.system(size: 11))
                        .padding(3)
                        .background(Circle().fill(isDark ? Color(hex: 0x0F172A) : Color.white))
                        .shadow(radius: 2)
                        .offset(x: 20, y: -20)
                }

                // Floating Hearts / Sparkles Particles
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: 18))
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .offset(x: particle.offsetX, y: particle.offsetY)
                }
            }
            .frame(width: 64, height: 64)
            .contentShape(Circle())
            // Gesture: Tap to pet or open modal
            .onTapGesture {
                handleCatPet()
            }
            .onLongPressGesture {
                MiodiHapticFeedback.notebookOpen()
                onOpenModal()
            }
            // Gesture: Drag / Swipe to pet smoothly
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { _ in
                        triggerPurrReaction()
                    }
            )
        }
        .onAppear {
            PetProgressionService.applyTimeDecay(pet: pet)
            if currentQuote.isEmpty {
                currentQuote = MaineCoonPhrases.dailyWisdomQuote(completedTasks: 0, totalTasks: 0)
            }
        }
    }

    // MARK: - Petting & Purring Logic
    private func handleCatPet() {
        PetProgressionService.petTheCat(pet: pet)
        triggerPurrReaction()
    }

    private func triggerPurrReaction() {
        MiodiHapticFeedback.purr()
        isPurring = true

        // Spawn floating heart particle
        let emojis = ["❤️", "💖", "🐾", "✨", "😻"]
        let randomEmoji = emojis.randomElement()!
        let startX = CGFloat.random(in: -15...15)
        var newParticle = FloatingHeartParticle(emoji: randomEmoji, startX: startX, startY: 0)
        particles.append(newParticle)

        withAnimation(.easeOut(duration: 1.2)) {
            if let index = particles.firstIndex(where: { $0.id == newParticle.id }) {
                particles[index].offsetY = -65.0
                particles[index].offsetX = startX + CGFloat.random(in: -18...18)
                particles[index].scale = 1.2
                particles[index].opacity = 0.0
            }
        }

        // Clean up particle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            particles.removeAll(where: { $0.id == newParticle.id })
        }

        // Stop purr vibration after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurring = false
        }

        // Update speech bubble with authentic quote
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showSpeechBubble = true
            currentQuote = MaineCoonPhrases.randomHeadPetQuote()
        }

        scheduleBubbleAutoDismiss()
    }

    private func cycleCatQuote() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if pet.isSleeping {
                currentQuote = MaineCoonPhrases.sleepingQuote()
            } else if pet.hungerPercent <= 30 {
                currentQuote = MaineCoonPhrases.hungryReminderQuote()
            } else {
                currentQuote = [
                    MaineCoonPhrases.randomHeadPetQuote(),
                    MaineCoonPhrases.randomBellyPetQuote(),
                    MaineCoonPhrases.dailyWisdomQuote(completedTasks: 1, totalTasks: 3)
                ].randomElement()!
            }
        }
        scheduleBubbleAutoDismiss()
    }

    private func scheduleBubbleAutoDismiss() {
        bubbleDismissTimer?.cancel()
        bubbleDismissTimer = Task {
            try? await Task.sleep(nanoseconds: 7_000_000_000) // 7 seconds
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                showSpeechBubble = false
            }
        }
    }
}
