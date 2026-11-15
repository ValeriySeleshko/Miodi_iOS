//
//  MaineCoonPhrases.swift
//  Plan4U_iOS
//
//  Authentic phrase and reaction catalog matching Android MaineCoonPhraseCatalog.kt.
//  Includes petting reactions, munch sounds, thankful quotes, and motivational cat wisdom.
//

import Foundation

public enum MaineCoonPhrases {

    // MARK: - Petting Reactions
    public static func randomHeadPetQuote() -> String {
        [
            "Мррр... прямо за ушком! Обожаю, когда ты так чешешь! 🥰🐾",
            "Жмурю глазки от удовольствия... Почеши ещё макушку! ✨",
            "Мои кисточки на ушках дрожат от счастья! Муррр! 💖",
            "Мяу! Это самое приятное место на свете! 🌸",
            "Мррр-мяу! У тебя самые заботливые ручки! 🐱"
        ].randomElement()!
    }

    public static func randomBellyPetQuote() -> String {
        [
            "Ахаха, щекотно же! Муррр! Пузико довольно! 💖",
            "Мррр-тррр... Включил свой мурчащий моторчик на полную! 😻",
            "Только тебе разрешаю погладить моё пушистое пузико! 💕",
            "Мурррр... Не останавливайся, человек! 🧶",
            "Какое счастье! Растекаюсь как тёплый блинчик... 🥞✨"
        ].randomElement()!
    }

    public static func randomPawPetQuote() -> String {
        [
            "Мяу! Лапки выпускают коготки и сразу прячут... Мурр! 🐾",
            "Щекочешь подушечки лапок! Мяу-мяу! ✨",
            "Дай пять пушистой лапкой! Ты отлично справляешься! 🐾⭐️",
            "Мррр... потягиваю мягкие лапки навстречу тебе! 🌸"
        ].randomElement()!
    }

    // MARK: - Feeding Reactions
    public static func munchQuote(isGoldenTreat: Bool) -> String {
        if isGoldenTreat {
            return [
                "Ням-ням-ням! Нежнейший паштет! МУРРР! 🥫💖✨",
                "Чавк-чавк! Это просто гастрономический восторг! 😋🐟",
                "Мррр! Какая вкуснятина! Облизываю усы! 😻✨"
            ].randomElement()!
        } else {
            return [
                "Хрусь-хрусь! Вкусные хрустящие камешки! Мурр! 🟤🐾",
                "Хрум-хрум-хрум! Энергия на весь день! ⚡️🐱",
                "Хрусть! Спасибо за сытный перекус, друг! 🥣✨"
            ].randomElement()!
        }
    }

    public static func thankfulQuote(isGoldenTreat: Bool) -> String {
        if isGoldenTreat {
            return "Муррр! Это было божественно вкусно! Спасибо за заботу! 🥫💖✨"
        } else {
            return "Мурррр! Животик сыт и доволен, спасибо за угощение! 🟤💕"
        }
    }

    public static func hungryReminderQuote() -> String {
        [
            "Мяу... Животик жалобно урчит. Покорми меня, пожалуйста! 🐟🥺",
            "Мяу? Ты выполнил задачу? В мисочке пусто... 🥣🐾",
            "Мррр, человеку нужен кофе, а котику — вкусные камешки! 🐟"
        ].randomElement()!
    }

    // MARK: - Sleeping Quotes
    public static func sleepingQuote() -> String {
        [
            "Хррр-пссс... сплю сладко... Zzz 💤",
            "Свернулся клубочком... снятся рыбки и лакомства 🧶🐟",
            "Zzz... тссс, котик набирается сил для новых дел... 😴✨",
            "Мррр... сплю на мягком пледике... Zzz 🌸"
        ].randomElement()!
    }

    // MARK: - Daily Wisdom & Productivity Tips
    public static func dailyWisdomQuote(completedTasks: Int, totalTasks: Int) -> String {
        if totalTasks > 0 && completedTasks == totalTasks {
            return "Ура-а-а! Все задачи закрыты! Ты просто герой, дай лапку! 🏆🐾✨"
        }
        if completedTasks > 0 {
            return "Отличный темп! Уже \(completedTasks) задач позади. Муррр, горжусь тобой! ⭐️"
        }
        return [
            "Привет, друг! Мяу! Готов планировать великие свершения? 👋✨",
            "Выполни важную задачу и получи вкусняшку для меня! 🐾🥫",
            "Не забывай пить водичку и сладко потягиваться, как я! 💧🐱",
            "Маленькие шаги ведут к большим победам! Я верю в тебя! 🌟",
            "У нас всё получится! Кисточки на ушках на макушке! 😉✨"
        ].randomElement()!
    }

    // MARK: - Laser Game Quotes
    public static func laserChaseQuote() -> String {
        [
            "Красная точка!! Я тебя сейчас поймаю! Вжууух! 🔴⚡️",
            "Куда она прыгнула?! Мои лапки быстрее скорости света! 🔴🐾",
            "Цель захвачена! Прыг-скок! Не уйдёшь, огонёк! 🎯🔴"
        ].randomElement()!
    }
}
