//
//  Locale+TimeStyle.swift
//  myminermonitor
//
//  Created by Aron Springfield on 19/05/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

enum LocaleClockStyle {
    case twentyFourHourClock
    case twelveHourClock
}

extension Locale {
    static func clockStyle() -> LocaleClockStyle {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        let is24HourClock = pmRange == nil && amRange == nil
        return is24HourClock ? .twentyFourHourClock : .twelveHourClock
    }
}
