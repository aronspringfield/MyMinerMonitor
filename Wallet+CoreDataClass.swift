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
    
    let secondsInAnHour: Double = 60 * 60
    let secondsInADay: Double = 60 * 60 * 24
    var walletSnapshots: [WalletSnapshot]?
    var profitIn1Hour: Double?
    var profitIn24Hours: Double?
    
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
    
    func isUpdating() -> Bool {
        return PoolRequest.isRequestActive(for: self)
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
        
        
        updateWalletSnapshots()
        updateRecentEarningAmounts()
    }
    
    func updateWalletSnapshots() {
        guard let walletIdentifier = walletIdentifier else {
            assert(false, "We're trying to update wallet snapshots without a walletIdentifier!?")
            return
        }
        let fetchRequest: NSFetchRequest<WalletSnapshot> = WalletSnapshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "walletIdentifier == %@", walletIdentifier)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let moc = DataStore.sharedInstance.persistentContainer.viewContext
        do {
            let results = try moc.fetch(fetchRequest)
            self.walletSnapshots = results
        }
        catch {
            // TODO
        }
    }
    
    func updateRecentEarningAmounts() {
        profitIn1Hour = nil
        profitIn24Hours = nil
        
        guard let snapshots = self.walletSnapshots,
            let latestSnapshot = snapshots.first,
            let latestSnapshotDate = latestSnapshot.timestamp as Date?,
            snapshots.count > 1,
            let oneDayAgo = NSCalendar.current.date(byAdding: .day, value: -1, to: latestSnapshotDate) else {
                return
        }
        
        for i in 1..<snapshots.count {
            let snapshot = snapshots[i]
            if let timestamp = snapshot.timestamp as Date? {
                if timestamp <= oneDayAgo {
                    if let interpWallet = findEstimatedWalletData(between: latestSnapshot,
                                                                  and: snapshot,
                                                                  secondsFromFirstWallet: secondsInADay) {
                        profitIn24Hours = interpWallet.total
                    }
                }
            }
            else {
                assert(false, "Timestamp is nil? Why?")
            }
        }
        
        guard let oneHourAgo = NSCalendar.current.date(byAdding: .hour, value: -1, to: latestSnapshotDate) else {
            return
        }
        
        for i in 1..<snapshots.count {
            let snapshot = snapshots[i]
            if let timestamp = snapshot.timestamp as Date? {
                if timestamp <= oneHourAgo {
                    if let interpWallet = findEstimatedWalletData(between: latestSnapshot,
                                                                  and: snapshot,
                                                                  secondsFromFirstWallet: secondsInAnHour) {
                        profitIn1Hour = interpWallet.total
                    }
                }
            }
            else {
                assert(false, "Timestamp is nil? Why?")
            }
        }
    }
    
    func findEstimatedWalletData(between firstWallet: WalletSnapshot, and secondWallet: WalletSnapshot, secondsFromFirstWallet: Double) -> PoolWalletData? {
        guard let firstDate = firstWallet.timestamp as Date?,
            let secondDate = secondWallet.timestamp as Date? else {
                assert(false, "Couldn't find the dates to interpolate between")
                return nil
        }
        let timeGap = firstDate.timeIntervalSince1970 - secondDate.timeIntervalSince1970
        let interpolateModifier = secondsFromFirstWallet / timeGap
        
        var walletData = PoolWalletData(address: "", pool: Pool.unknown)
        walletData.total = interpolateModifier * (firstWallet.total - secondWallet.total)
        walletData.unpaid = interpolateModifier * (firstWallet.unpaid - secondWallet.unpaid)
        walletData.unsold = interpolateModifier * (firstWallet.unsold - secondWallet.unsold)
        walletData.paid24Hour = interpolateModifier * (firstWallet.paid24Hour - secondWallet.paid24Hour)
        walletData.balance = interpolateModifier * (firstWallet.balance - secondWallet.balance)
        
        return walletData
    }
}
