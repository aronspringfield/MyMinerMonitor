//
//  Double+CurrencyToString.swift
//  myminermonitor
//
//  Created by Aron on 18/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

extension Double {
    func toCurrencyString() -> String {
        return String(format: "%.08f", self)
    }
}
