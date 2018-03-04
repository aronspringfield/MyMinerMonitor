//
//  ZPoolPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class ZPoolPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .zpool
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://www.zpool.ca/api/walletEx?address="
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
        
        // missing total_paid
        // adds paid24h, miners
    }
}
