//
//  HashRefineryPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class HashRefineryPoolRequest: PoolRequest {
    
    internal override func pool() -> Pool {
        return .hashRefinery
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://pool.hashrefinery.com/api/wallet?address="
    }
}
