//
//  Fugu15App.swift
//  Fugu15
//
//  Created by Linus Henze.
//

import SwiftUI
import LunarCore

var isFestivalDay: Bool = {
    let date = Date()
    let calendar = Calendar.current
    let lunar = Lunar(date: date)
    let day = calendar.component(.day, from: date)
    let month = calendar.component(.month, from: date)
    let lunarMonth = lunar.lunarMonth
    let lunarDay = lunar.lunarDay

    let festivalDays: [(Int, Int)] = [
        (1, 1),   // 元旦
        (12, 31), // 除夕
        (1, 1),   // 春节
        (1, 15),  // 元宵节
        (3, 8),   // 妇女节
        (6, 1),   // 儿童节
        (7, 1),   // 建党节
        (4, 4),   // 清明节
        (5, 1),   // 劳动节
        (5, 5),   // 端午节
        (9, 10),  // 教师节
        (8, 15),  // 中秋节
        (10, 1),  // 国庆节
        (11, 11),  // 光棍节
        (12, 25)  // 圣诞节
    ]

    for festival in festivalDays {
        if (festival.0 == month && festival.1 == day) || (festival.0 == lunarMonth && festival.1 == lunarDay) {
            return true
        }
    }

    return false
}()

struct Fugu15App: App {
    var body: some Scene {
        WindowGroup {
            JailbreakView()
        }
    }
}
