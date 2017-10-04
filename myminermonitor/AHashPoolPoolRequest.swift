//
//  AHashPoolPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 18/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class AHashPoolPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .aHashPool
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://www.ahashpool.com/api/wallet?address="
    }
}
