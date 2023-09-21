//
//  Fugu15App.swift
//  Fugu15
//
//  Created by Linus Henze.
//

import SwiftUI

var whatCouldThisVariablePossiblyEvenMean = {
    let date = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .month], from: date)

    return (components.day == 29 && components.month == 9) || (components.day == 1 && components.month == 10) || (components.day == 11 && components.month == 11) || (components.day == 25 && components.month == 12)
}()

struct Fugu15App: App {
    var body: some Scene {
        WindowGroup {
            JailbreakView()
        }
    }
}
