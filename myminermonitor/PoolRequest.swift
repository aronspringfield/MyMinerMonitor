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
    case blazePool = "blazepool"
    case zergPool = "zergPool"
    case mineMoney = "mineMoney"
    case phiPhiPool = "phiPhiPool"
    case blockMasters = "blockMasters"
    
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
        case .blazePool:
            return BlazePoolPoolRequest(wallet: wallet)
        case .zergPool:
            return ZergPoolPoolRequest(wallet: wallet)
        case .mineMoney:
            return MineMoneyPoolRequest(wallet: wallet)
        case .phiPhiPool:
            return PhiPhiPoolPoolRequest(wallet: wallet)
        case .blockMasters:
            return BlockMastersPoolRequest(wallet: wallet)
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
                walletData = PoolWalletData(address: address,
                                            pool: self.pool(),
                                            currency: wallet.currency)
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
                if let responseString = String(data: data, encoding: .utf8) {
                    print("raw response: \(responseString)")
                }
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
        
        if let total = response["total_paid"] as? NSNumber {
            walletData?.totalPaid = total.doubleValue
        }
        if let balance = response["balance"] as? NSNumber {
            walletData?.balance = balance.doubleValue
        }
        if let unpaid = response["total_unpaid"] as? NSNumber {
            walletData?.totalUnpaid = unpaid.doubleValue
        }
        if let currency = response["currency"] as? String {
            walletData?.currency = Currency(rawValue: currency) ?? .unknown
        }
        if let paid24Hour = response["total_earned"] as? NSNumber {
            walletData?.totalEarned = paid24Hour.doubleValue
        }
        if let unsold = response["unsold"] as? NSNumber {
            walletData?.unsold = unsold.doubleValue
        }
        let minerIds = self.minerIds(from: response["miners"])
        for minerId in minerIds {
            walletData?.activeMiners.append(minerId)
        }
    }
    
    internal func minerIds(from minersResponse: AnyObject?) -> [String] {
        var minerIds: [String] = []
        guard let miners = minersResponse as? [[String: AnyObject]],
            miners.count > 0 else {
                return minerIds
        }
        
        let minerIdSuffix: String
        if let walletData = walletData {
            let shortenedAddress = walletData.address.substring(to: walletData.address.index(walletData.address.startIndex, offsetBy: 4))
            minerIdSuffix = " -> " + walletData.pool.rawValue + " -> " + shortenedAddress + "..."
        }
        else {
            minerIdSuffix = ""
        }
        
        for miner in miners {
            if let idName = miner["ID"] as? String,
                idName.count > 0 {
                minerIds.append(idName + minerIdSuffix)
                continue
            }
            if let passwordField = miner["password"] as? String {
                let params = passwordField.components(separatedBy: ",")
                let idParams = params.compactMap { return $0.starts(with: "ID=") ? $0 : nil }
                if let idParam = idParams.first,
                    let idName = idParam.components(separatedBy: "=").last {
                    minerIds.append(idName + minerIdSuffix)
                    continue
                }
            }
            minerIds.append("*Unnamed Miner*" + minerIdSuffix)
        }
        return minerIds
    }
}
