//
//  MineMoneyPoolRequest.swift
//  myminermonitor
//
//  Created by Aron Springfield on 03/05/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

class MineMoneyPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .mineMoney
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://minemoney.co/api/walletEx?address="
    }
}
