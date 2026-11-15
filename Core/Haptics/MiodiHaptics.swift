//
//  MiodiHaptics.swift
//  Plan4U_iOS
//
//  Premium Taptic Engine feedback mirroring Android Vibrator behavior.
//

import UIKit

public enum MiodiHapticFeedback {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Soft tick when switching tabs or calendar days
    public static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    /// Light click when tapping regular buttons or toggling subtasks
    public static func lightClick() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred(intensity: 0.65)
    }

    /// Medium tactile pop when striking through a completed task
    public static func taskComplete() {
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred(intensity: 0.85)
    }

    /// Strong affirmative pulse when creating a task or claiming quest reward
    public static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    /// Rhythmic pyrotechnic salute fanfare feedback when completing all 3 joys of the day!
    public static func triumphSalute() {
        heavyGenerator.prepare()
        heavyGenerator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            lightGenerator.prepare()
            lightGenerator.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Grand celebration fanfare for habit formation milestones (7, 21, 66, 100 days)
    public static func celebrationFanfare() {
        heavyGenerator.prepare()
        heavyGenerator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Crisp icy double-tap when activating habit freeze (vacation mode)
    public static func iceFreeze() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        }
    }

    /// Joy mood slider scrubber feedback
    public static func moodStepTick() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    /// Warning/Destructive pulse when deleting a note or task
    public static func warning() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Custom mechanical double-tap feel for notebook cover open
    public static func notebookOpen() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred(intensity: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 0.8)
        }
    }

    /// Gentle purring micro-vibration when petting Maine Coon cat
    public static func purr() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            lightGenerator.prepare()
            lightGenerator.impactOccurred(intensity: 0.35)
        }
    }
}
