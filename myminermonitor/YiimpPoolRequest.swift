//
//  YiimpPoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class YiimpPoolRequest: PoolRequest {
    
    internal override func pool() -> Pool {
        return .yiimp
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://yiimp.ccminer.org/api/wallet?address="
    }
}
