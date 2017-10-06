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
        profitIn1Hour = 0
        profitIn24Hours = 0
        
        guard let snapshots = self.walletSnapshots,
            let latestSnapshot = snapshots.first,
            snapshots.count > 1 else {
                return
        }
        
        if let oneHourAgoWallet = findEstimatedWalletData(inTheLast: secondsInAnHour) {
            let differenceWallet = findWalletChangeBetween(walletSnapshot: latestSnapshot,
                                                           walletData: oneHourAgoWallet)
            profitIn1Hour = differenceWallet.total
        }
        
        if let oneDayAgoWallet = findEstimatedWalletData(inTheLast: secondsInADay) {
            let differenceWallet = findWalletChangeBetween(walletSnapshot: latestSnapshot,
                                                           walletData: oneDayAgoWallet)
            profitIn24Hours = differenceWallet.total
        }
    }
    
    func findEstimatedWalletData(inTheLast secondsSinceLatestWallet: Double) -> PoolWalletData? {
        guard let snapshots = self.walletSnapshots,
            let latestSnapshot = snapshots.first,
            let latestSnapshotDate = latestSnapshot.timestamp as Date?,
            snapshots.count > 1,
            let timeOfEstimateWallet = NSCalendar.current.date(byAdding: .second,
                                                               value: Int(-secondsSinceLatestWallet),
                                                               to: latestSnapshotDate) else {
                return nil
        }
        
        for i in 1..<snapshots.count {
            let earlierSnapshot = snapshots[i]
            if let timestamp = earlierSnapshot.timestamp as Date? {
                if timestamp <= timeOfEstimateWallet {
                    let laterSnapshot = snapshots[i-1]
                    
                    guard let earlierDate = earlierSnapshot.timestamp as Date?,
                        let laterDate = laterSnapshot.timestamp as Date? else {
                            assert(false, "Couldn't find the dates to interpolate between")
                            return nil
                    }
                    
                    let timeGap = laterDate.timeIntervalSince1970 - earlierDate.timeIntervalSince1970
                    let timeSinceLaterDate = latestSnapshotDate.timeIntervalSince1970 - laterDate.timeIntervalSince1970
                    let timeToSimulate = secondsSinceLatestWallet - timeSinceLaterDate
                    let multiplier = timeToSimulate / timeGap
                    
                    var walletData = PoolWalletData(address: "", pool: Pool.unknown)
                    walletData.total = laterSnapshot.total - (laterSnapshot.total - earlierSnapshot.total) * multiplier
                    walletData.unpaid = laterSnapshot.unpaid - (laterSnapshot.unpaid - earlierSnapshot.unpaid) * multiplier
                    walletData.unsold = laterSnapshot.unsold - (laterSnapshot.unsold - earlierSnapshot.unsold) * multiplier
                    walletData.paid24Hour = laterSnapshot.paid24Hour - (laterSnapshot.paid24Hour - earlierSnapshot.paid24Hour) * multiplier
                    walletData.balance = laterSnapshot.balance - (laterSnapshot.balance - earlierSnapshot.balance) * multiplier
                    return walletData
                }
            }
            else {
                assert(false, "Timestamp is nil? Why?")
            }
        }
        
        return nil
    }
    
    func findWalletChangeBetween(walletSnapshot: WalletSnapshot, walletData: PoolWalletData) -> PoolWalletData {
        var diffWallet = PoolWalletData(address: "", pool: Pool.unknown)
        diffWallet.total = walletSnapshot.total - walletData.total
        diffWallet.unpaid = walletSnapshot.unpaid - walletData.unpaid
        diffWallet.unsold = walletSnapshot.unsold - walletData.unsold
        diffWallet.paid24Hour = walletSnapshot.paid24Hour - walletData.paid24Hour
        diffWallet.balance = walletSnapshot.balance - walletData.balance
        return diffWallet
    }
}
