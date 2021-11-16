//
//  BlazePoolPoolRequest.swift
//  
//
//  Created by Aron on 03/03/2018.
//

import UIKit

class BlazePoolPoolRequest: PoolRequest {

    internal override func pool() -> Pool {
        return .blazePool
    }
    
    override internal func walletUpdateBaseUrl() -> String? {
        return "http://api.blazepool.com/wallet/"
    }
}
