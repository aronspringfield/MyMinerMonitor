//
//  Wallet+CoreDataClass.swift
//  myminermonitor
//
//  Created by Aron on 08/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import Foundation
import CoreData

protocol WalletStatusDelegate: class {
    func walletDidBeginUpdating()
    func walletDidUpdate()
    func walletDidFailToUpdate()
}

@objc(Wallet)
public class Wallet: NSManagedObject {
    
    var walletIdentifier: String? {
        if let address = self.address {
            return address + self.pool.rawValue
        }
        return nil
    }
    weak var delegate: WalletStatusDelegate?
    var updateFailed = false
    
    var identifier: String {
        get {
            assert(address != nil, "Address is nil but we're accessing the identifier!")
            guard let address = address else {
                return ""
            }
            return String(portfolioIdentifier) + "-" + pool.rawValue + "=" + address
        }
    }
    
    func update() {
        guard let poolRequest = PoolRequest.poolRequest(for: self.pool, wallet: self) else {
                assert(false, "Failed to find a pool request!")
                return
        }
        
        updateFailed = false
        delegate?.walletDidBeginUpdating()
        
        poolRequest.update { (success, walletData) in
            if success, let walletData = walletData {
                self.addWalletSnapshot(with: walletData)
                DispatchQueue.main.async {
                    self.delegate?.walletDidUpdate()
                    DataStore.sharedInstance.save()
                }
            }
            else {
                self.updateFailed = true
                DispatchQueue.main.async {
                    self.delegate?.walletDidFailToUpdate()
                }
                // TODO: Show failed UI
            }
        }
    }

    private func addWalletSnapshot(with walletData: PoolWalletData) {
        guard let walletIdentifier = self.walletIdentifier else {
            assert(false, "We have received a pool update without a wallet identifier?")
            return
        }
        let snapshot = DataStore.sharedInstance.insertNewWalletSnapshot(for: walletIdentifier,
                                                         walletData: walletData)
        self.total = snapshot.total
        self.unpaid = snapshot.unpaid
        self.unsold = snapshot.unsold
        self.paid24Hour = snapshot.paid24Hour
        self.balance = snapshot.balance
        self.updatedTimestamp = snapshot.timestamp
    }
    
    func isUpdating() -> Bool {
        return PoolRequest.isRequestActive(for: self)
    }
}
