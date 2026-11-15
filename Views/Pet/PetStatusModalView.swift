//
//  PetStatusModalView.swift
//  Plan4U_iOS
//
//  Complete 100% Port of Android PetModal.kt.
//  Includes Friendship Level, Coat Color Selector (9 palettes), Stat Meters (Hunger & Happiness),
//  Feeding Inventory (Pebbles & Treats), Interactive Petting Zones, Care Rituals, and Laser Mini-game.
//

import SwiftUI
import SwiftData

public struct PetStatusModalView: View {
    @Bindable public var pet: PetItem
    @Environment(\.dismiss) private var dismiss
    @Environment(MiodiThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    @State private var isRenaming: Bool = false
    @State private var newPetName: String = ""
    @State private var currentQuote: String = ""
    @State private var isPurring: Bool = false
    @State private var isEating: Bool = false
    @State private var isLaserGameActive: Bool = false
    @State private var laserPosition: CGPoint = CGPoint(x: 100, y: 100)
    @State private var floatingHearts: [UUID] = []

    private var isDark: Bool {
        theme.isDarkThemeOverride ?? (colorScheme == .dark)
    }

    public init(pet: PetItem) {
        self.pet = pet
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Level & Trust Banner
                    levelHeaderCard

                    // 2. 9 Coat Color Swatches
                    coatColorSelector

                    // 3. Central Interactive Mascot Stage with Petting & Laser Game
                    catInteractiveStage

                    // 4. Status Meters (Hunger & Happiness)
                    statsCard

                    // 5. Feeding Inventory (Pebbles & Treats)
                    feedingInventoryCard

                    // 6. Care & Play Rituals (Laser, Comb, Sleep)
                    careRitualsCard

                    // Spacing for comfortable scrolling
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(isDark ? Color(hex: 0x0F131C) : Color(hex: 0xFDFBF7))
            .navigationTitle("Котик \(pet.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        newPetName = pet.name
                        isRenaming = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.currentAccent.primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.currentAccent.primary)
                }
            }
            .alert("Имя питомца", isPresented: $isRenaming) {
                TextField("Введите имя", text: $newPetName)
                Button("Сохранить") {
                    let trimmed = newPetName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        pet.name = String(trimmed.prefix(20))
                        pet.lastSaved = Date()
                        MiodiHapticFeedback.success()
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Как будут звать твоего пушистого Мейн-куна?")
            }
        }
        .onAppear {
            PetProgressionService.applyTimeDecay(pet: pet)
            currentQuote = MaineCoonPhrases.dailyWisdomQuote(completedTasks: 0, totalTasks: 0)
        }
    }

    // MARK: - 1. Level & Trust Header Card
    private var levelHeaderCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Уровень \(pet.level)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))

                        Text("🐾")
                            .font(.system(size: 15))
                    }

                    Text(pet.trustTitle)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.currentAccent.primary)
                }

                Spacer()

                // Mood pill
                HStack(spacing: 4) {
                    Text(pet.mood.emoji)
                        .font(.system(size: 14))
                    Text(pet.mood.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isDark ? Color(hex: 0x1E2433) : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                )
            }

            // XP Bar
            VStack(spacing: 4) {
                GeometryReader { proxy in
                    let ratio = CGFloat(pet.currentXp) / CGFloat(max(1, pet.maxXp))
                    let fillWidth = max(6, proxy.size.width * min(1.0, ratio))

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isDark ? Color(hex: 0x2A3142) : Color(hex: 0xE2E8F0))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xEC4899), theme.currentAccent.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Опыт доверия")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))

                    Spacer()

                    Text("\(pet.currentXp) / \(pet.maxXp) XP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color(hex: 0x181D29) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.06), radius: 8, x: 0, y: 3)
        )
    }

    // MARK: - 2. Coat Color Selector (9 Authentic Colors)
    private var coatColorSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Окрас Мейн-куна")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MaineCoonPalettes.all) { palette in
                        let isSelected = (pet.color == palette.id)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                pet.color = palette.id
                                pet.lastSaved = Date()
                            }
                            MiodiHapticFeedback.selection()
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: palette.swatchColors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x334155) : Color(hex: 0xCBD5E1)),
                                                    lineWidth: isSelected ? 3 : 1
                                                )
                                        )

                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(palette.id == "white" ? Color.black : Color.white)
                                    }
                                }

                                Text(palette.name)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? theme.currentAccent.primary : (isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B)))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 3. Central Interactive Mascot Stage
    private var catInteractiveStage: some View {
        VStack(spacing: 8) {
            // Speech Bubble
            HStack(spacing: 6) {
                Text(pet.mood.emoji)
                    .font(.system(size: 14))

                Text(currentQuote)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDark ? Color(hex: 0x222938) : Color(hex: 0xFFFBEB))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.08), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDark ? Color(hex: 0x384256) : Color(hex: 0xF97316).opacity(0.35), lineWidth: 1.2)
            )

            // Cat Vector with Petting Zones
            ZStack {
                MaineCoonIllustratedCatView(
                    colorScheme: pet.color,
                    isSleeping: pet.isSleeping,
                    isPurring: isPurring,
                    isEating: isEating
                )
                .frame(width: 220, height: 220)

                // Laser mini-game red dot
                if isLaserGameActive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .shadow(color: Color.red.opacity(0.8), radius: 8, x: 0, y: 0)
                        .position(laserPosition)
                        .onTapGesture {
                            handleLaserCatch()
                        }
                }

                // Interactive Petting Zones (Head, Belly, Paws)
                if !isLaserGameActive {
                    VStack(spacing: 0) {
                        // Head Zone
                        Color.clear
                            .frame(height: 70)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                triggerHeadPet()
                            }

                        // Belly Zone
                        Color.clear
                            .frame(height: 65)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                triggerBellyPet()
                            }

                        // Paws Zone
                        Color.clear
                            .frame(height: 55)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                triggerPawPet()
                            }
                    }
                    .frame(width: 190, height: 190)
                }
            }
            .frame(width: 200, height: 200)

            // Petting action hint pills
            HStack(spacing: 8) {
                petHintButton(title: "Почесать ушко", icon: "sparkles") {
                    triggerHeadPet()
                }

                petHintButton(title: "Погладить пузико", icon: "heart.fill") {
                    triggerBellyPet()
                }

                petHintButton(title: "Пожать лапку", icon: "pawprint.fill") {
                    triggerPawPet()
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func petHintButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF1F5F9))
            )
            .foregroundStyle(isDark ? Color(hex: 0xCBD5E1) : Color(hex: 0x475569))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Status Meters (Hunger & Happiness)
    private var statsCard: some View {
        HStack(spacing: 14) {
            // Hunger Meter
            statMeter(
                title: "Сытость",
                percent: pet.hungerPercent,
                icon: "fish.fill",
                color: pet.hungerPercent <= 30 ? Color.orange : Color(hex: 0x10B981)
            )

            // Happiness Meter
            statMeter(
                title: "Счастье",
                percent: pet.happinessPercent,
                icon: "heart.fill",
                color: Color(hex: 0xEC4899)
            )
        }
    }

    private func statMeter(title: String, percent: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))

                Spacer()

                Text("\(percent)%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            GeometryReader { proxy in
                let fillWidth = proxy.size.width * CGFloat(min(100, max(0, percent))) / 100.0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(isDark ? Color(hex: 0x2A3142) : Color(hex: 0xE2E8F0))

                    Capsule()
                        .fill(color)
                        .frame(width: fillWidth)
                }
            }
            .frame(height: 7)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color(hex: 0x181D29) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - 5. Feeding Inventory Card
    private var feedingInventoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Угощения котика")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))

            HStack(spacing: 12) {
                // Dry Food Pebble
                feedingItemRow(
                    emoji: "🟤",
                    title: "Сухой корм",
                    count: pet.stoneCount,
                    gainText: "+15% сытость • +15 XP",
                    actionTitle: "Покормить"
                ) {
                    handleFeedStone()
                }

                // Wet Food Treat Jar
                feedingItemRow(
                    emoji: "🥫",
                    title: "Паштет",
                    count: pet.treatCount,
                    gainText: "+25% сытость • +25 XP",
                    actionTitle: "Угостить"
                ) {
                    handleFeedTreat()
                }
            }

            // Reward info banner
            HStack(alignment: .top, spacing: 8) {
                Text("🐾")
                    .font(.system(size: 15))

                Text("Выполняй обычные задачи блокнота и секретные квесты Мейни (🐾), чтобы получать новые порции корма и лакомств!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                    .lineSpacing(2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDark ? Color(hex: 0x1E2433).opacity(0.6) : Color(hex: 0xF8FAFC))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color(hex: 0x181D29) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 8, x: 0, y: 3)
        )
    }

    private func feedingItemRow(
        emoji: String,
        title: String,
        count: Int,
        gainText: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(emoji)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))

                    Text("\(count) шт.")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(count > 0 ? theme.currentAccent.primary : Color.gray)
                }

                Spacer()
            }

            Text(gainText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isDark ? Color(hex: 0x94A3B8) : Color(hex: 0x64748B))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(count > 0 ? theme.currentAccent.primary : (isDark ? Color(hex: 0x2A3142) : Color(hex: 0xE2E8F0)))
                    )
                    .foregroundStyle(count > 0 ? Color.white : (isDark ? Color(hex: 0x64748B) : Color(hex: 0x94A3B8)))
            }
            .buttonStyle(.plain)
            .disabled(count <= 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC))
        )
    }

    // MARK: - 6. Care & Play Rituals Card
    private var careRitualsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Игры и забота")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color.white : Color(hex: 0x1E293B))

            HStack(spacing: 10) {
                // Laser Pointer
                ritualButton(
                    icon: "target",
                    title: isLaserGameActive ? "Остановить лазер" : "Лазерная указка",
                    color: Color.red
                ) {
                    toggleLaserGame()
                }

                // Grooming Brush
                ritualButton(
                    icon: "comb.fill",
                    title: "Причесать шерсть",
                    color: Color.purple
                ) {
                    handleBrushFur()
                }

                // Sleep / Wake
                ritualButton(
                    icon: pet.isSleeping ? "sun.max.fill" : "moon.stars.fill",
                    title: pet.isSleeping ? "Разбудить" : "Уложить спать",
                    color: Color(hex: 0x6366F1)
                ) {
                    toggleSleep()
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color(hex: 0x181D29) : Color.white)
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 8, x: 0, y: 3)
        )
    }

    private func ritualButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isDark ? Color(hex: 0xE2E8F0) : Color(hex: 0x334155))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDark ? Color(hex: 0x1E2433) : Color(hex: 0xF8FAFC))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions & Handlers
    private func triggerHeadPet() {
        PetProgressionService.petTheCat(pet: pet)
        MiodiHapticFeedback.purr()
        isPurring = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = MaineCoonPhrases.randomHeadPetQuote()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurring = false
        }
    }

    private func triggerBellyPet() {
        PetProgressionService.petTheCat(pet: pet)
        MiodiHapticFeedback.purr()
        isPurring = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = MaineCoonPhrases.randomBellyPetQuote()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurring = false
        }
    }

    private func triggerPawPet() {
        PetProgressionService.petTheCat(pet: pet)
        MiodiHapticFeedback.lightClick()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = MaineCoonPhrases.randomPawPetQuote()
        }
    }

    private func handleFeedStone() {
        guard pet.stoneCount > 0 else { return }
        _ = PetProgressionService.feedStone(pet: pet)
        MiodiHapticFeedback.success()
        isEating = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = MaineCoonPhrases.munchQuote(isGoldenTreat: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isEating = false
            withAnimation {
                currentQuote = MaineCoonPhrases.thankfulQuote(isGoldenTreat: false)
            }
        }
    }

    private func handleFeedTreat() {
        guard pet.treatCount > 0 else { return }
        _ = PetProgressionService.feedTreat(pet: pet)
        MiodiHapticFeedback.success()
        isEating = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = MaineCoonPhrases.munchQuote(isGoldenTreat: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isEating = false
            withAnimation {
                currentQuote = MaineCoonPhrases.thankfulQuote(isGoldenTreat: true)
            }
        }
    }

    private func handleBrushFur() {
        _ = PetProgressionService.brushFur(pet: pet)
        MiodiHapticFeedback.purr()
        isPurring = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentQuote = "Мррр... Шёрстка блестит и переливается на солнышке! Спасибо! ✨🐱"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurring = false
        }
    }

    private func toggleSleep() {
        pet.isSleeping.toggle()
        pet.lastSaved = Date()
        MiodiHapticFeedback.selection()
        withAnimation(.easeInOut(duration: 0.3)) {
            if pet.isSleeping {
                currentQuote = MaineCoonPhrases.sleepingQuote()
            } else {
                currentQuote = "Сладко потягиваюсь! С добрым утром, друг! Мяу! 🌅🐾"
            }
        }
    }

    private func toggleLaserGame() {
        isLaserGameActive.toggle()
        MiodiHapticFeedback.selection()
        if isLaserGameActive {
            currentQuote = MaineCoonPhrases.laserChaseQuote()
            relocateLaser()
        }
    }

    private func handleLaserCatch() {
        _ = PetProgressionService.playWithLaser(pet: pet)
        MiodiHapticFeedback.lightClick()
        isEating = true // Bounce animation
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            currentQuote = MaineCoonPhrases.laserChaseQuote()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isEating = false
            relocateLaser()
        }
    }

    private func relocateLaser() {
        withAnimation(.easeInOut(duration: 0.2)) {
            laserPosition = CGPoint(
                x: CGFloat.random(in: 40...160),
                y: CGFloat.random(in: 40...160)
            )
        }
    }
}
