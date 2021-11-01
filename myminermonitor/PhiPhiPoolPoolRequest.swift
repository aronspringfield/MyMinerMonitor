//
//  PhiPhiPoolPoolRequest.swift
//  myminermonitor
//
//  Created by Aron Springfield on 03/05/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

class PhiPhiPoolPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .phiPhiPool
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://www.phi-phi-pool.net/api/walletEx?address="
    }
}
