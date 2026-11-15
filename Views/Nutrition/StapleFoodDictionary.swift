//
//  StapleFoodDictionary.swift
//  Plan4U_iOS
//
//  Curated high-accuracy food database matching Android StapleFoodDictionary.
//

import Foundation

public struct StapleFoodItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let nameEn: String
    public let calories: Double
    public let proteins: Double
    public let fats: Double
    public let carbs: Double
    public let category: String
    public let aliases: [String]

    public init(
        id: String,
        name: String,
        nameEn: String,
        calories: Double,
        proteins: Double,
        fats: Double,
        carbs: Double,
        category: String,
        aliases: [String] = []
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.calories = calories
        self.proteins = proteins
        self.fats = fats
        self.carbs = carbs
        self.category = category
        self.aliases = aliases
    }
}

public enum StapleFoodDictionary {
    public static let allItems: [StapleFoodItem] = [
        // MARK: - Птица и мясо
        StapleFoodItem(id: "s_5001", name: "Куриное филе (сырое)", nameEn: "Chicken breast (raw)", calories: 113, proteins: 23.6, fats: 1.9, carbs: 0.4, category: "Мясо и птица", aliases: ["курица", "грудка", "курочка", "филе"]),
        StapleFoodItem(id: "s_5002", name: "Куриное филе (варёное)", nameEn: "Chicken breast (boiled)", calories: 165, proteins: 31.0, fats: 3.6, carbs: 0.0, category: "Мясо и птица", aliases: ["курица вареная", "вареная грудка"]),
        StapleFoodItem(id: "s_5003", name: "Куриное бедро (без кожи)", nameEn: "Chicken thigh (skinless)", calories: 185, proteins: 19.5, fats: 12.0, carbs: 0.2, category: "Мясо и птица", aliases: ["бедро куриное", "бедрышко"]),
        StapleFoodItem(id: "s_5004", name: "Филе индейки (сырое)", nameEn: "Turkey breast (raw)", calories: 104, proteins: 21.6, fats: 1.5, carbs: 0.0, category: "Мясо и птица", aliases: ["индейка", "грудка индейки"]),
        StapleFoodItem(id: "s_5005", name: "Филе индейки (варёное)", nameEn: "Turkey breast (boiled)", calories: 135, proteins: 29.0, fats: 1.8, carbs: 0.0, category: "Мясо и птица", aliases: ["индейка вареная"]),
        StapleFoodItem(id: "s_5006", name: "Говядина нежирная", nameEn: "Beef lean", calories: 158, proteins: 22.0, fats: 7.8, carbs: 0.0, category: "Мясо и птица", aliases: ["говядина", "вырезка", "телятина"]),
        StapleFoodItem(id: "s_5007", name: "Говядина тушёная", nameEn: "Beef stewed", calories: 195, proteins: 25.5, fats: 10.2, carbs: 0.0, category: "Мясо и птица", aliases: ["тушеная говядина"]),
        StapleFoodItem(id: "s_5008", name: "Фарш говяжий нежирный", nameEn: "Ground beef lean", calories: 182, proteins: 21.0, fats: 10.8, carbs: 0.0, category: "Мясо и птица", aliases: ["фарш"]),
        StapleFoodItem(id: "s_5009", name: "Свинина нежирная (вырезка)", nameEn: "Pork tenderloin", calories: 143, proteins: 21.0, fats: 6.5, carbs: 0.0, category: "Мясо и птица", aliases: ["свинина", "вырезка свиная"]),

        // MARK: - Рыба и морепродукты
        StapleFoodItem(id: "s_5020", name: "Лосось / Сёмга", nameEn: "Salmon", calories: 206, proteins: 20.0, fats: 13.0, carbs: 0.0, category: "Рыба и морепродукты", aliases: ["лосось", "семга", "форель"]),
        StapleFoodItem(id: "s_5021", name: "Минтай (сырой)", nameEn: "Pollock (raw)", calories: 72, proteins: 15.9, fats: 0.9, carbs: 0.0, category: "Рыба и морепродукты", aliases: ["минтай", "белая рыба"]),
        StapleFoodItem(id: "s_5022", name: "Треска (сырая)", nameEn: "Cod (raw)", calories: 82, proteins: 17.8, fats: 0.7, carbs: 0.0, category: "Рыба и морепродукты", aliases: ["треска"]),
        StapleFoodItem(id: "s_5023", name: "Тунец в собственном соку", nameEn: "Canned tuna in water", calories: 109, proteins: 25.0, fats: 1.0, carbs: 0.0, category: "Рыба и морепродукты", aliases: ["тунец", "тунец консервированный"]),
        StapleFoodItem(id: "s_5024", name: "Креветки очищенные", nameEn: "Shrimp peeled", calories: 99, proteins: 24.0, fats: 0.3, carbs: 0.2, category: "Рыба и морепродукты", aliases: ["креветки"]),
        StapleFoodItem(id: "s_5025", name: "Кальмар (варёный)", nameEn: "Squid boiled", calories: 110, proteins: 22.0, fats: 1.8, carbs: 1.5, category: "Рыба и морепродукты", aliases: ["кальмар"]),

        // MARK: - Яйца и молочные продукты
        StapleFoodItem(id: "s_5030", name: "Яйцо куриное (1 шт ~55г)", nameEn: "Egg whole (1 pc ~55g)", calories: 143, proteins: 12.6, fats: 9.5, carbs: 0.7, category: "Молочные продукты и яйца", aliases: ["яйцо", "яйца"]),
        StapleFoodItem(id: "s_5031", name: "Белок яичный", nameEn: "Egg white", calories: 52, proteins: 11.0, fats: 0.2, carbs: 0.7, category: "Молочные продукты и яйца", aliases: ["белок", "яичный белок"]),
        StapleFoodItem(id: "s_5032", name: "Творог 0% (обезжиренный)", nameEn: "Cottage cheese 0%", calories: 71, proteins: 16.5, fats: 0.2, carbs: 1.3, category: "Молочные продукты и яйца", aliases: ["творог обезжиренный"]),
        StapleFoodItem(id: "s_5033", name: "Творог 5%", nameEn: "Cottage cheese 5%", calories: 121, proteins: 17.2, fats: 5.0, carbs: 1.8, category: "Молочные продукты и яйца", aliases: ["творог 5%", "творог"]),
        StapleFoodItem(id: "s_5034", name: "Творог 9%", nameEn: "Cottage cheese 9%", calories: 159, proteins: 16.7, fats: 9.0, carbs: 2.0, category: "Молочные продукты и яйца", aliases: ["творог 9%"]),
        StapleFoodItem(id: "s_5035", name: "Греческий йогурт 2%", nameEn: "Greek yogurt 2%", calories: 73, proteins: 8.0, fats: 2.0, carbs: 4.5, category: "Молочные продукты и яйца", aliases: ["йогурт греческий", "йогурт"]),
        StapleFoodItem(id: "s_5036", name: "Молоко 2.5%", nameEn: "Milk 2.5%", calories: 52, proteins: 2.9, fats: 2.5, carbs: 4.7, category: "Молочные продукты и яйца", aliases: ["молоко"]),
        StapleFoodItem(id: "s_5037", name: "Молоко 3.2%", nameEn: "Milk 3.2%", calories: 60, proteins: 2.9, fats: 3.2, carbs: 4.7, category: "Молочные продукты и яйца", aliases: ["молоко"]),
        StapleFoodItem(id: "s_5038", name: "Сыр Твёрдый (Российский / Гауда)", nameEn: "Hard cheese (Gouda)", calories: 356, proteins: 25.0, fats: 28.0, carbs: 0.0, category: "Молочные продукты и яйца", aliases: ["сыр", "твердый сыр"]),
        StapleFoodItem(id: "s_5039", name: "Моцарелла", nameEn: "Mozzarella cheese", calories: 280, proteins: 22.0, fats: 21.0, carbs: 2.2, category: "Молочные продукты и яйца", aliases: ["моцарелла"]),
        StapleFoodItem(id: "s_5040", name: "Сыр Пармезан", nameEn: "Parmesan cheese", calories: 431, proteins: 38.0, fats: 29.0, carbs: 4.1, category: "Молочные продукты и яйца", aliases: ["пармезан"]),
        StapleFoodItem(id: "s_5041", name: "Кефир 1%", nameEn: "Kefir 1%", calories: 40, proteins: 2.8, fats: 1.0, carbs: 4.0, category: "Молочные продукты и яйца", aliases: ["кефир"]),
        StapleFoodItem(id: "s_5042", name: "Сметана 15%", nameEn: "Sour cream 15%", calories: 158, proteins: 2.6, fats: 15.0, carbs: 3.0, category: "Молочные продукты и яйца", aliases: ["сметана"]),

        // MARK: - Крупы, злаки и гарниры
        StapleFoodItem(id: "s_5050", name: "Гречневая каша (варёная)", nameEn: "Buckwheat (boiled)", calories: 101, proteins: 3.8, fats: 1.1, carbs: 20.0, category: "Крупы и гарниры", aliases: ["гречка", "греча", "вареная гречка"]),
        StapleFoodItem(id: "s_5051", name: "Гречневая крупа (сухая)", nameEn: "Buckwheat (raw)", calories: 313, proteins: 12.6, fats: 3.3, carbs: 62.1, category: "Крупы и гарниры", aliases: ["гречка сухая"]),
        StapleFoodItem(id: "s_5052", name: "Овсяная каша на воде (варёная)", nameEn: "Oatmeal (boiled on water)", calories: 88, proteins: 3.0, fats: 1.7, carbs: 15.0, category: "Крупы и гарниры", aliases: ["овсянка", "геркулес", "каша"]),
        StapleFoodItem(id: "s_5053", name: "Овсяные хлопья (сухие)", nameEn: "Rolled oats (dry)", calories: 366, proteins: 11.9, fats: 7.2, carbs: 69.3, category: "Крупы и гарниры", aliases: ["овсянка сухая", "хлопья"]),
        StapleFoodItem(id: "s_5054", name: "Рис белый (варёный)", nameEn: "White rice (boiled)", calories: 116, proteins: 2.5, fats: 0.3, carbs: 25.0, category: "Крупы и гарниры", aliases: ["рис", "рис вареный"]),
        StapleFoodItem(id: "s_5055", name: "Рис бурый (варёный)", nameEn: "Brown rice (boiled)", calories: 112, proteins: 2.6, fats: 0.9, carbs: 23.5, category: "Крупы и гарниры", aliases: ["бурый рис", "коричневый рис"]),
        StapleFoodItem(id: "s_5056", name: "Макароны твёрдых сортов (варёные)", nameEn: "Pasta (boiled)", calories: 131, proteins: 5.0, fats: 1.1, carbs: 25.0, category: "Крупы и гарниры", aliases: ["макароны", "спагетти", "паста"]),
        StapleFoodItem(id: "s_5057", name: "Картофель варёный", nameEn: "Potatoes (boiled)", calories: 82, proteins: 2.0, fats: 0.1, carbs: 18.0, category: "Крупы и гарниры", aliases: ["картошка", "картофель"]),
        StapleFoodItem(id: "s_5058", name: "Картофельное пюре с молоком", nameEn: "Mashed potatoes", calories: 106, proteins: 2.3, fats: 4.2, carbs: 15.0, category: "Крупы и гарниры", aliases: ["пюре"]),
        StapleFoodItem(id: "s_5059", name: "Хлеб цельнозерновой", nameEn: "Whole wheat bread", calories: 213, proteins: 8.5, fats: 2.0, carbs: 41.0, category: "Крупы и гарниры", aliases: ["хлеб", "цельнозерновой"]),
        StapleFoodItem(id: "s_5060", name: "Хлеб белый (батон)", nameEn: "White bread", calories: 265, proteins: 7.5, fats: 2.9, carbs: 50.0, category: "Крупы и гарниры", aliases: ["батон", "белый хлеб"]),
        StapleFoodItem(id: "s_5061", name: "Хлебцы ржаные / злаковые", nameEn: "Crispbread rye", calories: 310, proteins: 10.0, fats: 2.5, carbs: 60.0, category: "Крупы и гарниры", aliases: ["хлебцы"]),
        StapleFoodItem(id: "s_5062", name: "Киноа (варёная)", nameEn: "Quinoa (boiled)", calories: 120, proteins: 4.4, fats: 1.9, carbs: 21.3, category: "Крупы и гарниры", aliases: ["киноа"]),
        StapleFoodItem(id: "s_5063", name: "Чечевица (варёная)", nameEn: "Lentils (boiled)", calories: 116, proteins: 9.0, fats: 0.4, carbs: 20.0, category: "Крупы и гарниры", aliases: ["чечевица"]),

        // MARK: - Овощи и зелень
        StapleFoodItem(id: "s_5070", name: "Огурцы свежие", nameEn: "Cucumbers fresh", calories: 15, proteins: 0.8, fats: 0.1, carbs: 3.0, category: "Овощи и зелень", aliases: ["огурец", "огурцы"]),
        StapleFoodItem(id: "s_5071", name: "Помидоры свежие", nameEn: "Tomatoes fresh", calories: 18, proteins: 0.9, fats: 0.2, carbs: 3.9, category: "Овощи и зелень", aliases: ["помидор", "томаты"]),
        StapleFoodItem(id: "s_5072", name: "Перец болгарский сладкий", nameEn: "Bell pepper sweet", calories: 27, proteins: 1.3, fats: 0.1, carbs: 5.3, category: "Овощи и зелень", aliases: ["перец", "болгарский перец"]),
        StapleFoodItem(id: "s_5073", name: "Брокколи свежая / на пару", nameEn: "Broccoli steamed", calories: 34, proteins: 2.8, fats: 0.4, carbs: 6.6, category: "Овощи и зелень", aliases: ["брокколи"]),
        StapleFoodItem(id: "s_5074", name: "Цветная капуста", nameEn: "Cauliflower", calories: 25, proteins: 2.0, fats: 0.3, carbs: 4.2, category: "Овощи и зелень", aliases: ["цветная капуста"]),
        StapleFoodItem(id: "s_5075", name: "Капуста белокочанная", nameEn: "White cabbage fresh", calories: 25, proteins: 1.3, fats: 0.1, carbs: 4.7, category: "Овощи и зелень", aliases: ["капуста"]),
        StapleFoodItem(id: "s_5076", name: "Морковь свежая", nameEn: "Carrots fresh", calories: 35, proteins: 1.3, fats: 0.1, carbs: 6.9, category: "Овощи и зелень", aliases: ["морковь", "морковка"]),
        StapleFoodItem(id: "s_5077", name: "Шпинат свежий", nameEn: "Spinach fresh", calories: 23, proteins: 2.9, fats: 0.4, carbs: 2.0, category: "Овощи и зелень", aliases: ["шпинат"]),
        StapleFoodItem(id: "s_5078", name: "Кабачки свежие", nameEn: "Zucchini fresh", calories: 17, proteins: 1.2, fats: 0.3, carbs: 3.1, category: "Овощи и зелень", aliases: ["кабачок", "цукини"]),
        StapleFoodItem(id: "s_5079", name: "Шампиньоны свежие", nameEn: "Mushrooms fresh", calories: 22, proteins: 3.1, fats: 0.3, carbs: 3.3, category: "Овощи и зелень", aliases: ["грибы", "шампиньоны"]),

        // MARK: - Фрукты и ягоды
        StapleFoodItem(id: "s_5090", name: "Яблоко свежее", nameEn: "Apple fresh", calories: 52, proteins: 0.3, fats: 0.2, carbs: 13.8, category: "Фрукты и ягоды", aliases: ["яблоко", "яблоки"]),
        StapleFoodItem(id: "s_5091", name: "Банан свежий", nameEn: "Banana fresh", calories: 89, proteins: 1.1, fats: 0.3, carbs: 22.8, category: "Фрукты и ягоды", aliases: ["банан", "бананы"]),
        StapleFoodItem(id: "s_5092", name: "Апельсин свежий", nameEn: "Orange fresh", calories: 43, proteins: 0.9, fats: 0.2, carbs: 8.1, category: "Фрукты и ягоды", aliases: ["апельсин"]),
        StapleFoodItem(id: "s_5093", name: "Авокадо", nameEn: "Avocado", calories: 160, proteins: 2.0, fats: 14.7, carbs: 8.5, category: "Фрукты и ягоды", aliases: ["авокадо"]),
        StapleFoodItem(id: "s_5094", name: "Клубника свежая", nameEn: "Strawberries fresh", calories: 33, proteins: 0.7, fats: 0.3, carbs: 7.7, category: "Фрукты и ягоды", aliases: ["клубника", "ягоды"]),
        StapleFoodItem(id: "s_5095", name: "Голубика свежая", nameEn: "Blueberries fresh", calories: 57, proteins: 0.7, fats: 0.3, carbs: 14.5, category: "Фрукты и ягоды", aliases: ["голубика", "черника"]),
        StapleFoodItem(id: "s_5096", name: "Груша свежая", nameEn: "Pear fresh", calories: 57, proteins: 0.4, fats: 0.1, carbs: 15.2, category: "Фрукты и ягоды", aliases: ["груша"]),
        StapleFoodItem(id: "s_5097", name: "Киви", nameEn: "Kiwi", calories: 61, proteins: 1.1, fats: 0.5, carbs: 14.7, category: "Фрукты и ягоды", aliases: ["киви"]),

        // MARK: - Орехи и масла
        StapleFoodItem(id: "s_5110", name: "Грецкие орехи", nameEn: "Walnuts", calories: 654, proteins: 15.2, fats: 65.2, carbs: 7.0, category: "Орехи и масла", aliases: ["орехи", "грецкий"]),
        StapleFoodItem(id: "s_5111", name: "Миндаль", nameEn: "Almonds", calories: 579, proteins: 21.2, fats: 49.9, carbs: 21.6, category: "Орехи и масла", aliases: ["миндаль"]),
        StapleFoodItem(id: "s_5112", name: "Арахисовая паста (без сахара)", nameEn: "Peanut butter pure", calories: 588, proteins: 25.0, fats: 50.0, carbs: 20.0, category: "Орехи и масла", aliases: ["арахисовая паста"]),
        StapleFoodItem(id: "s_5113", name: "Масло оливковое", nameEn: "Olive oil", calories: 884, proteins: 0.0, fats: 100.0, carbs: 0.0, category: "Орехи и масла", aliases: ["оливковое масло", "масло"]),
        StapleFoodItem(id: "s_5114", name: "Масло сливочное 82.5%", nameEn: "Butter 82.5%", calories: 748, proteins: 0.5, fats: 82.5, carbs: 0.8, category: "Орехи и масла", aliases: ["сливочное масло"]),

        // MARK: - Супы и готовые блюда
        StapleFoodItem(id: "s_5140", name: "Борщ с говядиной", nameEn: "Borscht with beef", calories: 62, proteins: 3.2, fats: 2.5, carbs: 6.8, category: "Супы и блюда", aliases: ["борщ", "красный борщ"]),
        StapleFoodItem(id: "s_5141", name: "Суп куриный с лапшой", nameEn: "Chicken noodle soup", calories: 48, proteins: 3.5, fats: 1.8, carbs: 4.5, category: "Супы и блюда", aliases: ["куриный суп", "суп с лапшой"]),
        StapleFoodItem(id: "s_5142", name: "Суп овощной", nameEn: "Vegetable soup", calories: 43, proteins: 1.5, fats: 1.2, carbs: 6.5, category: "Супы и блюда", aliases: ["овощной суп"]),
        StapleFoodItem(id: "s_5143", name: "Сырники из творога (запечённые)", nameEn: "Baked cottage cheese pancakes", calories: 185, proteins: 15.0, fats: 6.5, carbs: 16.0, category: "Супы и блюда", aliases: ["сырники", "творожники"]),
        StapleFoodItem(id: "s_5144", name: "Омлет из 2 яиц с молоком", nameEn: "Omelette with milk", calories: 135, proteins: 10.5, fats: 9.5, carbs: 2.0, category: "Супы и блюда", aliases: ["омлет", "яичница"])
    ]

    public static func search(query: String) -> [StapleFoodItem] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.isEmpty {
            return allItems
        }
        let tokens = clean.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        if tokens.isEmpty {
            return allItems
        }

        return allItems.filter { item in
            let searchable = "\(item.name) \(item.nameEn) \(item.aliases.joined(separator: " "))".lowercased()
            return tokens.allSatisfy { token in searchable.contains(token) }
        }
    }
}
