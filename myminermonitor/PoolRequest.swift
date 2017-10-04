//
//  PoolRequest.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

enum Pool : String {
    case unknown = "unknown"
    case yiimp = "yiimp"
    case zpool = "zpool"
    case hashRefinery = "hashRefinery"
    case aHashPool = "ahashpool"
    case niceHash = "nicehash"
    
    init(safeRawValue: String) {
        self = Pool(rawValue: safeRawValue) ?? .unknown
    }
}

protocol PoolRequestDelegte {
    func walletDidUpdate(_ wallet: PoolWalletData)
}

class PoolRequest {
    
    private(set) weak var wallet: Wallet?
    private static var activeRequests = [String: Bool]()
    
    var walletData: PoolWalletData?
    
    class func poolRequest(for pool: Pool, wallet: Wallet) -> PoolRequest? {
        switch pool {
        case .yiimp:
            return YiimpPoolRequest(wallet: wallet)
        case .zpool:
            return ZPoolPoolRequest(wallet: wallet)
        case .hashRefinery:
            return HashRefineryPoolRequest(wallet: wallet)
        case .aHashPool:
            return AHashPoolPoolRequest(wallet: wallet)
        case .niceHash:
            return NiceHashPoolRequest(wallet: wallet)
        case .unknown:
            return nil
        }
    }
    
    class func isRequestActive(for wallet: Wallet) -> Bool {
        return activeRequests[wallet.identifier] != nil
    }
    
    class func setRequest(isActive: Bool, for wallet: Wallet) {
        activeRequests[wallet.identifier] = isActive ? true : nil
    }

    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    private func requestUrl() -> URL? {
        guard let walletUpdateBaseUrl = walletUpdateBaseUrl() else {
            return nil
        }
        guard let adddress = wallet?.address,
            let url = URL(string: walletUpdateBaseUrl + adddress) else {
            return nil
        }
        return url
    }

    func update(responseHandler: ((Bool, PoolWalletData?) -> ())?) {
        guard let wallet = wallet,
            let url = requestUrl() else {
            responseHandler?(false, nil)
            return
        }
        
        if walletData == nil {
            if let address = wallet.address {
                walletData = PoolWalletData(address: address, pool: self.pool())
            }
            assert(walletData != nil, "Wallet is unexpectedly nil")
        }
        
        PoolRequest.setRequest(isActive: true, for: wallet)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            PoolRequest.setRequest(isActive: false, for: wallet)
            guard let data = data else {
                responseHandler?(false, nil)
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject] {
                    self.processResponse(jsonResponse)
                    responseHandler?(true, self.walletData)
                }
            } catch let parseError {
                print("parsing error: \(parseError)")
                let responseString = String(data: data, encoding: .utf8)
                print("raw response: \(responseString)")
                responseHandler?(false, nil)
            }
        }
        task.resume()
    }
    
    // Abtract Methods
    
    internal func pool() -> Pool {
        return .unknown
    }
    
    internal func walletUpdateBaseUrl() -> String? {
        return nil
    }
    
    internal func processResponse(_ response: [String: AnyObject]) {
        assert(walletData != nil, "Wallet data should not be nil")
        
        if let total = response["total"] as? NSNumber {
            walletData?.total = total.doubleValue
        }
        if let paid24Hour = response["paid24h"] as? NSNumber {
            walletData?.paid24Hour = paid24Hour.doubleValue
        }
        if let balance = response["balance"] as? NSNumber {
            walletData?.balance = balance.doubleValue
        }
        if let unpaid = response["unpaid"] as? NSNumber {
            walletData?.unpaid = unpaid.doubleValue
        }
        if let currency = response["currency"] as? String {
            walletData?.currency = Currency(rawValue: currency) ?? .unknown
        }
        if let unsold = response["unsold"] as? NSNumber {
            walletData?.balance = unsold.doubleValue
        }
        
        assert(walletData?.total != nil, "Missing data")
        assert(walletData?.paid24Hour != nil, "Missing data")
        assert(walletData?.balance != nil, "Missing data")
        assert(walletData?.unpaid != nil, "Missing data")
        assert(walletData?.currency != nil, "Missing data")
        assert(walletData?.balance != nil, "Missing data")
    }
}
