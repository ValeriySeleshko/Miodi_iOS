//
//  JoyModel.swift
//  Plan4U_iOS
//
//  Joy of the Day (Радость дня) domain models, catalog, and prompt data.
//  100% parity with Android JoyMoodCatalog.kt and JoyPromptsData.kt.
//

import SwiftUI

// MARK: - Joy Mood Data Model
public struct JoyMood: Identifiable, Sendable {
    public let step: Int
    public let id: String
    public let assetPath: String
    public let emoji: String
    public let titleRu: String
    public let titleUk: String
    public let titleEn: String

    public init(
        step: Int,
        id: String,
        assetPath: String,
        emoji: String,
        titleRu: String,
        titleUk: String,
        titleEn: String
    ) {
        self.step = step
        self.id = id
        self.assetPath = assetPath
        self.emoji = emoji
        self.titleRu = titleRu
        self.titleUk = titleUk
        self.titleEn = titleEn
    }

    public func title(for languageCode: String = "ru") -> String {
        switch languageCode.lowercased() {
        case "uk": return titleUk
        case "en": return titleEn
        default: return titleRu
        }
    }
}

// MARK: - Quick Mood Preset
public struct JoyQuickMood: Identifiable, Hashable, Sendable {
    public let id: String
    public let emoji: String
    public let title: String
    public let step: Int
    public let color: Color

    public init(id: String, emoji: String, title: String, step: Int, color: Color) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.step = step
        self.color = color
    }
}

// MARK: - Joy Mood Catalog (20 Steps)
public enum JoyMoodCatalog {
    public static let allMoods: [JoyMood] = [
        JoyMood(step: 1,  id: "mood_01", assetPath: "joy_mood/joy_mood_01.png", emoji: "✨", titleRu: "Восторг",   titleUk: "Захват",    titleEn: "Ecstatic"),
        JoyMood(step: 2,  id: "mood_02", assetPath: "joy_mood/joy_mood_02.png", emoji: "😄", titleRu: "Счастье",   titleUk: "Щастя",     titleEn: "Happy"),
        JoyMood(step: 3,  id: "mood_03", assetPath: "joy_mood/joy_mood_03.png", emoji: "😃", titleRu: "Радость",   titleUk: "Радість",   titleEn: "Joyful"),
        JoyMood(step: 4,  id: "mood_04", assetPath: "joy_mood/joy_mood_04.png", emoji: "😁", titleRu: "Подъем",    titleUk: "Підйом",    titleEn: "Great"),
        JoyMood(step: 5,  id: "mood_05", assetPath: "joy_mood/joy_mood_05.png", emoji: "😀", titleRu: "Отлично",   titleUk: "Чудово",    titleEn: "Awesome"),
        JoyMood(step: 6,  id: "mood_06", assetPath: "joy_mood/joy_mood_06.png", emoji: "😊", titleRu: "Уютно",     titleUk: "Затишно",   titleEn: "Cozy"),
        JoyMood(step: 7,  id: "mood_07", assetPath: "joy_mood/joy_mood_07.png", emoji: "😏", titleRu: "Игриво",    titleUk: "Грайливо",  titleEn: "Playful"),
        JoyMood(step: 8,  id: "mood_08", assetPath: "joy_mood/joy_mood_08.png", emoji: "🙂", titleRu: "Спокойно",  titleUk: "Спокійно",  titleEn: "Calm"),
        JoyMood(step: 9,  id: "mood_09", assetPath: "joy_mood/joy_mood_09.png", emoji: "😌", titleRu: "Хорошо",    titleUk: "Добре",     titleEn: "Good"),
        JoyMood(step: 10, id: "mood_10", assetPath: "joy_mood/joy_mood_10.png", emoji: "😐", titleRu: "В норме",   titleUk: "В нормі",   titleEn: "Neutral"),
        JoyMood(step: 11, id: "mood_11", assetPath: "joy_mood/joy_mood_11.png", emoji: "🤨", titleRu: "Непонятно", titleUk: "Незрозуміло", titleEn: "Uncertain"),
        JoyMood(step: 12, id: "mood_12", assetPath: "joy_mood/joy_mood_12.png", emoji: "😖", titleRu: "Стресс",    titleUk: "Стрес",     titleEn: "Uneasy"),
        JoyMood(step: 13, id: "mood_13", assetPath: "joy_mood/joy_mood_13.png", emoji: "🙁", titleRu: "Усталость", titleUk: "Втома",     titleEn: "Tired"),
        JoyMood(step: 14, id: "mood_14", assetPath: "joy_mood/joy_mood_14.png", emoji: "☹️", titleRu: "Держусь",   titleUk: "Тримаюся",  titleEn: "Holding on"),
        JoyMood(step: 15, id: "mood_15", assetPath: "joy_mood/joy_mood_15.png", emoji: "😞", titleRu: "Печаль",    titleUk: "Печаль",    titleEn: "Down"),
        JoyMood(step: 16, id: "mood_16", assetPath: "joy_mood/joy_mood_16.png", emoji: "😢", titleRu: "Обидно",    titleUk: "Прикро",    titleEn: "Hurt"),
        JoyMood(step: 17, id: "mood_17", assetPath: "joy_mood/joy_mood_17.png", emoji: "😭", titleRu: "Грустно",   titleUk: "Сумно",     titleEn: "Sad"),
        JoyMood(step: 18, id: "mood_18", assetPath: "joy_mood/joy_mood_18.png", emoji: "😫", titleRu: "Тяжело",    titleUk: "Важко",     titleEn: "Overwhelmed"),
        JoyMood(step: 19, id: "mood_19", assetPath: "joy_mood/joy_mood_19.png", emoji: "😱", titleRu: "Крик души", titleUk: "Крик душі", titleEn: "Despair"),
        JoyMood(step: 20, id: "mood_20", assetPath: "joy_mood/joy_mood_20.png", emoji: "💔", titleRu: "Бессилие",  titleUk: "Безсилля",  titleEn: "Heartbroken")
    ]

    /// 8 Authentic quick emoji-mood presets requested for rapid selection
    public static let quickPresets: [JoyQuickMood] = [
        JoyQuickMood(id: "sun",      emoji: "☀️",  title: "Солнце",   step: 3,  color: Color(hex: 0xF59E0B)),
        JoyQuickMood(id: "coffee",   emoji: "☕️",  title: "Кофе",     step: 6,  color: Color(hex: 0xD97706)),
        JoyQuickMood(id: "smile",    emoji: "😊",  title: "Улыбка",   step: 2,  color: Color(hex: 0xEC4899)),
        JoyQuickMood(id: "hug",      emoji: "🫂",  title: "Объятия",  step: 6,  color: Color(hex: 0x8B5CF6)),
        JoyQuickMood(id: "nature",   emoji: "🌿",  title: "Природа",  step: 8,  color: Color(hex: 0x10B981)),
        JoyQuickMood(id: "sparkle",  emoji: "✨",  title: "Восторг",  step: 1,  color: Color(hex: 0xFBBF24)),
        JoyQuickMood(id: "heart",    emoji: "💖",  title: "Тепло",    step: 6,  color: Color(hex: 0xF43F5E)),
        JoyQuickMood(id: "blossom",  emoji: "🌸",  title: "Уют",      step: 6,  color: Color(hex: 0xFB7185))
    ]

    public static func getMood(step: Int) -> JoyMood {
        let safeIndex = max(0, min(allMoods.count - 1, step - 1))
        return allMoods[safeIndex]
    }

    public static func resolveStep(from moodStr: String?) -> Int {
        guard let clean = moodStr?.trimmingCharacters(in: .whitespacesAndNewlines), !clean.isEmpty else {
            return 10 // Neutral default
        }

        if clean.lowercased().hasPrefix("mood_") {
            let numStr = clean.replacingOccurrences(of: "mood_", with: "", options: .caseInsensitive)
            if let num = Int(numStr), (1...20).contains(num) {
                return num
            }
        }
        if let num = Int(clean), (1...20).contains(num) {
            return num
        }

        let lower = clean.lowercased()
        if lower.contains("восторг") || lower.contains("захват") || lower.contains("ecstatic") || clean.contains("✨") { return 1 }
        if lower.contains("счаст") || lower.contains("щаст") || lower.contains("happy") || clean.contains("😄") { return 2 }
        if lower.contains("радост") || lower.contains("радіс") || lower.contains("joy") || clean.contains("☀️") || clean.contains("🎉") { return 3 }
        if lower.contains("подъем") || lower.contains("підйом") || lower.contains("great") || clean.contains("😁") { return 4 }
        if lower.contains("отлич") || lower.contains("чудов") || lower.contains("awesome") || clean.contains("😀") { return 5 }
        if lower.contains("уют") || lower.contains("затиш") || lower.contains("cozy") || clean.contains("☕️") || clean.contains("🫂") || clean.contains("💖") || clean.contains("🌸") { return 6 }
        if lower.contains("игрив") || lower.contains("грайлив") || lower.contains("playful") || clean.contains("😏") { return 7 }
        if lower.contains("спокой") || lower.contains("спокій") || lower.contains("calm") || clean.contains("🌿") || clean.contains("🙂") { return 8 }
        if lower.contains("хорош") || lower.contains("добре") || lower.contains("good") || clean.contains("😌") { return 9 }
        if lower.contains("норм") || lower.contains("neutral") || clean.contains("😐") { return 10 }
        if lower.contains("непонят") || lower.contains("незрозум") || lower.contains("uncertain") || clean.contains("🤨") { return 11 }
        if lower.contains("стресс") || lower.contains("стрес") || lower.contains("uneasy") || clean.contains("😖") { return 12 }
        if lower.contains("устал") || lower.contains("втом") || lower.contains("tired") || clean.contains("🙁") { return 13 }
        if lower.contains("держ") || lower.contains("трима") || lower.contains("holding") || clean.contains("☹️") || clean.contains("🌧") { return 14 }
        if lower.contains("печал") || lower.contains("down") || clean.contains("😞") { return 15 }
        if lower.contains("обид") || lower.contains("прикр") || lower.contains("hurt") || clean.contains("😢") { return 16 }
        if lower.contains("груст") || lower.contains("сумно") || lower.contains("sad") || clean.contains("😭") || clean.contains("🍂") { return 17 }
        if lower.contains("тяжел") || lower.contains("важко") || lower.contains("overwhelm") || clean.contains("😫") { return 18 }
        if lower.contains("крик") || lower.contains("despair") || clean.contains("😱") { return 19 }
        if lower.contains("бессил") || lower.contains("безсил") || lower.contains("heartbroken") || clean.contains("💔") { return 20 }

        return 10
    }

    public static func resolveMoodEmoji(from moodStr: String?) -> String {
        let step = resolveStep(from: moodStr)
        return getMood(step: step).emoji
    }

    public static func resolveMoodTitle(from moodStr: String?, languageCode: String = "ru") -> String {
        let step = resolveStep(from: moodStr)
        return getMood(step: step).title(for: languageCode)
    }
}

// MARK: - 25 Authentic Paper Sticker Variations
public enum JoyPaperStickers {
    public static let allStickers: [String] = (1...25).map { idx in
        let numStr = idx < 10 ? "0\(idx)" : "\(idx)"
        return "stickers/paper/paper_\(numStr).webp"
    }

    public static func randomSticker() -> String {
        allStickers.randomElement() ?? "stickers/paper/paper_17.webp"
    }
}

// MARK: - Daily Gratitude & Joy Reflection Prompts (25 Questions)
public struct JoyPromptItem: Identifiable, Sendable {
    public let id: Int
    public let ru: String
    public let uk: String
    public let en: String

    public func text(for langCode: String = "ru") -> String {
        switch langCode.lowercased() {
        case "uk": return uk
        case "en": return en
        default: return ru
        }
    }
}

public enum JoyPromptsData {
    public static let prompts: [JoyPromptItem] = [
        JoyPromptItem(id: 0,
            ru: "Был ли сегодня вкусный кофе, чай или любимая еда?",
            uk: "Чи була сьогодні смачна кава, чай або улюблена страва?",
            en: "Did you enjoy a delicious coffee, tea, or meal today?"),
        JoyPromptItem(id: 1,
            ru: "Кто сегодня сказал доброе слово или подарил улыбку?",
            uk: "Хто сьогодні сказав добре слово або щиро посміхнувся?",
            en: "Who gave you a kind word, a compliment, or a warm smile today?"),
        JoyPromptItem(id: 2,
            ru: "Какая музыка, видео или книга подняли настроение?",
            uk: "Яка музика, відео або книга підняли настрій?",
            en: "What song, video, or book lifted your spirits today?"),
        JoyPromptItem(id: 3,
            ru: "Удалось ли сегодня сделать паузу, выдохнуть и отдохнуть?",
            uk: "Чи вдалося сьогодні зробити паузу, видихнути та відпочити?",
            en: "Did you get a chance to take a deep breath and take a break?"),
        JoyPromptItem(id: 4,
            ru: "Какая маленькая победа или завершенное дело сегодня порадовали?",
            uk: "Яка маленька перемога або завершена справа сьогодні порадували?",
            en: "What small victory or finished task brought satisfaction?"),
        JoyPromptItem(id: 5,
            ru: "Какая погода, деталь природы или вид из окна зацепили взгляд?",
            uk: "Яка погода, краєвид чи деталь за вікном привернули погляд?",
            en: "What glimpse of nature, weather, or view outside caught your eye?"),
        JoyPromptItem(id: 6,
            ru: "За что в сегодняшнем дне хочется сказать тихое «спасибо»?",
            uk: "За що в сьогоднішньому дні хочеться сказати тихе «дякую»?",
            en: "What is one little thing from today you can say \"thank you\" for?"),
        JoyPromptItem(id: 7,
            ru: "Что сегодня заставило хотя бы на секунду улыбнуться?",
            uk: "Що сьогодні змусило хоча б на мить усміхнутися?",
            en: "What made you smile today, even for just a second?"),
        JoyPromptItem(id: 8,
            ru: "Какой уютный момент дома сегодня согрел душу?",
            uk: "Яка затишна мить удома сьогодні зігріла душу?",
            en: "What cozy moment at home warmed your heart today?"),
        JoyPromptItem(id: 9,
            ru: "Что приятное и заботливое получилось сделать для себя?",
            uk: "Що приємне й турботливе вдалося зробити для себе сьогодні?",
            en: "What nice, caring thing did you do for yourself today?"),
        JoyPromptItem(id: 10,
            ru: "Порадовали ли сегодня пушистые лапки, птицы или животные?",
            uk: "Чи порадували сьогодні пухнасті лапки, птахи або кумедні тваринки?",
            en: "Did a furry friend, birds, or a cute animal bring you joy today?"),
        JoyPromptItem(id: 11,
            ru: "Какой приятный запах или ощущение запомнились за день?",
            uk: "Який приємний аромат чи відчуття запам'яталися за день?",
            en: "What pleasant scent or texture stood out to you today?"),
        JoyPromptItem(id: 12,
            ru: "От кого сегодня было приятно получить весточку или звонок?",
            uk: "Від кого сьогодні було приємно отримати повідомлення чи дзвінок?",
            en: "Who sent you a sweet message or gave you a nice call today?"),
        JoyPromptItem(id: 13,
            ru: "Над какой шуткой, мемом или историей получилось искренне посмеяться?",
            uk: "З якого жарту, мему чи кумедної історії вдалося щиро посміятися?",
            en: "What joke, meme, or funny story made you laugh out loud today?"),
        JoyPromptItem(id: 14,
            ru: "С чем непростым получилось сегодня справиться, даже если не хотелось?",
            uk: "З чим непростим удалося сьогодні впоратися, навіть якщо не хотілося?",
            en: "What tricky task did you manage to tackle, even when it felt tough?"),
        JoyPromptItem(id: 15,
            ru: "Какую красивую мелочь вокруг удалось заметить на прогулке или в пути?",
            uk: "Яку гарну дрібничку довкола вдалося помітити на прогулянці чи в дорозі?",
            en: "What lovely little detail caught your attention while out and about?"),
        JoyPromptItem(id: 16,
            ru: "Каким сегодня было небо: закат, облака, звёзды или лучик солнца?",
            uk: "Яким сьогодні було небо: захід сонця, хмари, зорі чи сонячний промінь?",
            en: "How was the sky today: a sunset, clouds, stars, or a ray of sunshine?"),
        JoyPromptItem(id: 17,
            ru: "Удалось ли сегодня кому-то помочь или сделать чей-то день светлее?",
            uk: "Чи вдалося сьогодні комусь допомогти або зробити чийсь день світлішим?",
            en: "Did you get to help someone or brighten someone’s day today?"),
        JoyPromptItem(id: 18,
            ru: "Что интересное, любопытное или новое довелось сегодня узнать?",
            uk: "Що цікаве, незвичне або нове вдалося сьогодні дізнатися?",
            en: "What interesting or unexpected fact or idea did you discover today?"),
        JoyPromptItem(id: 19,
            ru: "Было ли сегодня сладкое угощение, фрукт или любимый перекус?",
            uk: "Чи був сьогодні солодкий смаколик, фрукт або улюблений перекус?",
            en: "Did you treat yourself to a sweet dessert, fresh fruit, or tasty snack?"),
        JoyPromptItem(id: 20,
            ru: "В каком месте или уголке сегодня было особенно спокойно и хорошо?",
            uk: "У якому місці чи куточку сьогодні було особливо спокійно й добре?",
            en: "Where did you feel especially peaceful, safe, and content today?"),
        JoyPromptItem(id: 21,
            ru: "Какая убранная полочка, чистый стол или вымытая чашка порадовали глаз?",
            uk: "Яка прибрана поличка, чистий стіл чи вимита чашка потішили око?",
            en: "Did an organized shelf, clear desk, or tidy spot give you satisfaction?"),
        JoyPromptItem(id: 22,
            ru: "Было ли сегодня теплое объятие, рукопожатие или душевный разговор?",
            uk: "Чи були сьогодні теплі обійми, міцне рукостискання або душевна розмова?",
            en: "Was there a warm hug, a handshake, or a heartfelt conversation today?"),
        JoyPromptItem(id: 23,
            ru: "Случилась ли сегодня приятная покупка или полезное приобретение?",
            uk: "Чи сталася сьогодні приємна покупка або корисне придбання?",
            en: "Did you make a nice purchase or treat yourself to something useful?"),
        JoyPromptItem(id: 24,
            ru: "За какую черту характера или поступок ты сегодня собой гордишься?",
            uk: "За яку рису характеру або вчинок ти сьогодні собою пишаєшся?",
            en: "What trait or action made you proud of yourself today?")
    ]

    public static func randomPrompt(excludeIndex: Int = -1, langCode: String = "ru") -> (index: Int, text: String) {
        guard !prompts.isEmpty else { return (-1, "") }
        let available = prompts.filter { $0.id != excludeIndex }
        let selected = available.randomElement() ?? prompts[0]
        return (selected.id, selected.text(for: langCode))
    }
}
