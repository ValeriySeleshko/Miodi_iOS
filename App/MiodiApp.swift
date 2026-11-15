//
//  MiodiApp.swift
//  Plan4U_iOS
//
//  Complete 100% Schema Miodi iOS Application Entry Point with SwiftData & Themes.
//

import SwiftUI
import SwiftData

@main
struct MiodiApp: App {
    @State private var themeManager = MiodiThemeManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            TabItem.self,
            SectionItem.self,
            HabitItem.self,
            HabitEntryItem.self,
            FinanceItem.self,
            DiaryItem.self,
            JoyItem.self,
            WeightEntryItem.self,
            MealItem.self,
            CustomFoodItem.self,
            CycleItem.self,
            PetItem.self,
            PageStickerItem.self,
            MomentItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NotebookMainView()
                .environment(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
