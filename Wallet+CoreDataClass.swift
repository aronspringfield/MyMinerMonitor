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

enum WalletUpdateResult: Int {
    case success
    case partialSuccess
    case failed
    case none
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
    
    func update(with completionHandler: ((_ success: Bool)->())? = nil) {
        guard let poolRequest = PoolRequest.poolRequest(for: self.pool, wallet: self) else {
            assert(false, "Failed to find a pool request!")
            completionHandler?(false)
            return
        }
        
        updateFailed = false
        delegate?.walletDidBeginUpdating()
        
        poolRequest.update { (success, walletData) in
            if success, let walletData = walletData {
                self.addWalletSnapshot(with: walletData)
                DispatchQueue.main.async {
                    DataStore.sharedInstance.save()
                    self.delegate?.walletDidUpdate()
                    completionHandler?(true)
                }
            }
            else {
                self.updateFailed = true
                DispatchQueue.main.async {
                    self.delegate?.walletDidFailToUpdate()
                    completionHandler?(false)
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
        self.currency = walletData.currency
        self.totalPaid = snapshot.totalPaid
        self.totalUnpaid = snapshot.totalUnpaid
        self.balance = snapshot.balance
        self.unsold = snapshot.unsold
        self.totalEarned = snapshot.totalEarned
        self.updatedTimestamp = snapshot.timestamp
        self.activeMiners = walletData.activeMiners
        
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
        profitIn1Hour = getLast1HourWalletSummary()?.totalEarned ?? 0
        profitIn24Hours = getLast24HoursWalletSummary()?.totalEarned ?? 0
    }
    
    func getLast1HourWalletSummary() -> PoolWalletData? {
        if walletSnapshots == nil {
            updateWalletSnapshots()
        }
        return getLatestWalletSummary(forTheLast: secondsInAnHour)
    }
    
    func getLast24HoursWalletSummary() -> PoolWalletData? {
        if walletSnapshots == nil {
            updateWalletSnapshots()
        }
        return getLatestWalletSummary(forTheLast: secondsInADay)
    }
    
    func getLatestWalletSummary(forTheLast secondsSinceLatestWallet: Double) -> PoolWalletData? {
        guard let snapshots = self.walletSnapshots,
            let latestSnapshot = snapshots.first,
            snapshots.count > 1 else {
                return nil
        }
        
        if let olderEstimatedWallet = findEstimatedWalletData(inTheLast: secondsSinceLatestWallet) {
            let differenceWallet = findWalletChangeBetween(walletSnapshot: latestSnapshot,
                                                           walletData: olderEstimatedWallet)
            return differenceWallet
        }
        
        return nil
    }
    
    func findEstimatedWalletData(inTheLast secondsSinceLatestWallet: Double) -> PoolWalletData? {
        guard
            let address = self.address,
            let snapshots = self.walletSnapshots,
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
                    
                    var walletData = PoolWalletData(address: address,
                                                    pool: self.pool,
                                                    currency: self.currency)
                    walletData.totalPaid = laterSnapshot.totalPaid - (laterSnapshot.totalPaid - earlierSnapshot.totalPaid) * multiplier
                    walletData.totalUnpaid = laterSnapshot.totalUnpaid - (laterSnapshot.totalUnpaid - earlierSnapshot.totalUnpaid) * multiplier
                    walletData.balance = laterSnapshot.balance - (laterSnapshot.balance - earlierSnapshot.balance) * multiplier
                    walletData.unsold = laterSnapshot.unsold - (laterSnapshot.unsold - earlierSnapshot.unsold) * multiplier
                    walletData.totalEarned = laterSnapshot.totalEarned - (laterSnapshot.totalEarned - earlierSnapshot.totalEarned) * multiplier
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
        var diffWallet = PoolWalletData(address: self.address ?? "",
                                        pool: self.pool,
                                        currency: self.currency)
        diffWallet.totalPaid = walletSnapshot.totalPaid - walletData.totalPaid
        diffWallet.totalUnpaid = walletSnapshot.totalUnpaid - walletData.totalUnpaid
        diffWallet.balance = walletSnapshot.balance - walletData.balance
        diffWallet.unsold = walletSnapshot.unsold - walletData.unsold
        diffWallet.totalEarned = walletSnapshot.totalEarned - walletData.totalEarned
        return diffWallet
    }
    
    // MARK: - Class Methods
    
    class func updateAllWallets(for portfolioIdentifier: Int64? = nil, with completionHandler: ((_ result: WalletUpdateResult, _ activeMiners: [String]?)->())?) {
        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()
        if let portfolioIdentifier = portfolioIdentifier {
            fetchRequest.predicate = NSPredicate(format: "portfolioIdentifier == %lu", portfolioIdentifier)
        }
        let context = DataStore.sharedInstance.persistentContainer.viewContext
        do {
            let allWallets = try context.fetch(fetchRequest)
            var updateResult = WalletUpdateResult.none
            var counter = 0
            let targetCount = allWallets.count
            guard targetCount > 0 else {
                completionHandler?(.none, nil)
                return
            }
            var activeMiners = [String]()
            for wallet in allWallets {
                activeMiners.append(contentsOf: wallet.activeMiners)
                wallet.update() { success in
                    counter += 1
                    NSLog("Wallet updated: \(success)")
                    
                    switch (success, updateResult) {
                    case (true, .failed),
                         (false, .success):
                        updateResult = .partialSuccess
                        break
                    case (_, .partialSuccess):
                        break
                    case (true, _):
                        updateResult = .success
                        break
                    case (false, _):
                        updateResult = .failed
                        break
                    }
                    
                    if counter >= targetCount {
                        // TODO: how do we wait for coredata save before completing?
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            context.perform {
                                completionHandler?(updateResult, activeMiners)
                            }
                        })
                    }
                }
            }
        }
        catch {
            assert(false, "Failed to fetch Wallets with error: \(error)")
            completionHandler?(.failed, nil)
        }
    }

}
