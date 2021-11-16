//
//  DataStructures.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

enum Currency: String {
    case unknown = "unknown"
    case bitcoin = "BTC"
    case verge = "XVG"
    case vertcoin = "VTC"
    
    init(safeRawValue: String) {
        self = Currency(rawValue: safeRawValue) ?? .unknown
    }
}

struct PoolWalletData {
    let address: String
    let pool: Pool
    var currency: Currency = .unknown
    var totalPaid: Double = 0
    var totalUnpaid: Double = 0
    var balance: Double = 0
    var unsold: Double = 0
    var totalEarned: Double = 0
    var activeMiners: [String] = []
    
    init(address: String, pool: Pool, currency: Currency) {
        self.address = address
        self.pool = pool
        self.currency = currency
    }
}
