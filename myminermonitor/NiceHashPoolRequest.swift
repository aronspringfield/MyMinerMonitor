//
//  NiceHashPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 18/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class NiceHashPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .niceHash
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "https://api.nicehash.com/api?method=stats.provider&addr="
    }
    
    internal override func processResponse(_ response: [String: AnyObject]) {
        assert(walletData != nil, "Wallet data should not be nil")
        guard let result = response["result"] as? [String: AnyObject],
            let stats = result["stats"] as? [[String: AnyObject]] else {
                return
        }
        
        var runningBalance: Double = 0
        for statObject in stats {
            if let amount = statObject["balance"]?.doubleValue {
                runningBalance += amount
            }
        }
        walletData?.balance = runningBalance
    }
}
