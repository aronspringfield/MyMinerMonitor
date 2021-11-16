//
//  WalletOverview.swift
//  myminermonitor
//
//  Created by Aron Springfield on 11/04/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

struct WalletOverview {
    var balance: Double = 0
    var totalUnpaid: Double = 0
    var totalPaid: Double = 0
    var totalEarned: Double = 0
    var totalPast1Hour: Double = 0
    var totalPast24Hours: Double = 0
    var activeMiners: [String] = []
    
    init(wallets: [Wallet]) {
        for wallet in wallets {
            if wallet.currency == .bitcoin {
                balance += wallet.balance
                totalEarned += wallet.totalEarned
                totalUnpaid += wallet.totalUnpaid
                totalPaid += wallet.totalPaid
                totalPast24Hours += wallet.profitIn24Hours
                totalPast1Hour += wallet.profitIn1Hour
            } else {
                // TODO: convert to bitcoin and add
            }
            for miner in wallet.activeMiners {
                activeMiners.append(miner)
            }
        }
    }
    
    init(walletData: [PoolWalletData]) {
        for wallet in walletData {
            if wallet.currency == .bitcoin {
                NSLog("Adding amount: \(wallet.balance). Running total: \(balance)")
                balance += wallet.balance
                totalEarned += wallet.totalEarned
                totalUnpaid += wallet.totalUnpaid
                totalPaid += wallet.totalPaid
                for miner in wallet.activeMiners {
                    activeMiners.append(miner)
                }
            }
            else {
                // TODO // convert to bitcoin and add
            }
        }
    }
}
