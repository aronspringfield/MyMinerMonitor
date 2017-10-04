//
//  DataStructures.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

enum Currency : String {
    case unknown = "unknown"
    case bitcoin = "BTC"
    case signatum = "SIGT"
    case verge = "XVG"
    
    init(safeRawValue: String) {
        self = Currency(rawValue: safeRawValue) ?? .unknown
    }
}

struct PoolWalletData {
    let address: String
    let pool: Pool
    var currency: Currency = .unknown
    var total: Double = 0
    var unpaid: Double = 0
    var unsold: Double = 0
    var paid24Hour: Double = 0
    var balance: Double = 0
    
    init(address: String, pool: Pool) {
        self.address = address
        self.pool = pool
    }
}
