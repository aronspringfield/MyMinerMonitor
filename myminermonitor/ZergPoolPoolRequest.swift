//
//  ZergPoolPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 03/03/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

class ZergPoolPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .zergPool
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://zergpool.com//api/walletEx?address="
    }
    
    internal override func processResponse(_ response: [String: AnyObject]) {
        assert(walletData != nil, "Wallet data should not be nil")
        
        if let total = response["total_paid"] as? NSNumber {
            walletData?.totalPaid = total.doubleValue
        }
        if let balance = response["balance"] as? NSNumber {
            walletData?.balance = balance.doubleValue
        }
        if let unpaid = response["unpaid"] as? NSNumber {
            walletData?.totalUnpaid = unpaid.doubleValue
        }
        if let currency = response["currency"] as? String {
            walletData?.currency = Currency(rawValue: currency) ?? .unknown
        }
        if let paid24Hour = response["total"] as? NSNumber {
            walletData?.totalEarned = paid24Hour.doubleValue
        }
        if let unsold = response["unsold"] as? NSNumber {
            walletData?.unsold = unsold.doubleValue
        }
        let minerIds = self.minerIds(from: response["miners"])
        for minerId in minerIds {
            walletData?.activeMiners.append(minerId)
        }
        
        //Missing total_paid, total_earned
        //Adds paid24h
    }
}
