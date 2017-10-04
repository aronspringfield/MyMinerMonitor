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
}
