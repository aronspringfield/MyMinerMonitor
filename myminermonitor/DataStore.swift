//
//  DataStore.swift
//  myminermonitor
//
//  Created by Aron on 09/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import CoreData

class DataStore: NSObject {

    static let sharedInstance = DataStore()
    let persistentContainer = NSPersistentContainer(name: "DataStore")
    
    func loadStore(handler: ((Bool) -> ())?) {
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
                handler?(false)
            } else {
                handler?(true)
            }
        }
    }
    
    func insertNewPortfolio(withName name: String) -> Portfolio {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Portfolio",
                                                         into: persistentContainer.viewContext) as! Portfolio
        entity.identifier = Int64(Date().timeIntervalSince1970)
        entity.name = name
        return entity
    }
    
    func insertNewWallet(for identifier: Int64, pool: Pool, address: String) -> Wallet {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Wallet",
                                                         into: persistentContainer.viewContext) as! Wallet
        entity.portfolioIdentifier = identifier
        entity.pool = pool
        entity.address = address
        return entity
    }
    
    func insertNewWalletSnapshot(for walletIdentifier: String, walletData: PoolWalletData) -> WalletSnapshot {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "WalletSnapshot",
                                                         into: persistentContainer.viewContext) as! WalletSnapshot
        entity.walletIdentifier = walletIdentifier
        entity.timestamp = NSDate()
        entity.totalPaid = walletData.totalPaid
        entity.totalUnpaid = walletData.totalUnpaid
        entity.balance = walletData.balance
        entity.unsold = walletData.unsold
        entity.totalEarned = walletData.totalEarned
        return entity
    }
    
    func save() {
        do {
        try persistentContainer.viewContext.save()
        } catch {
            print("Failed to save to context")
        }
    }
    
    func removeEntity(_ object: NSManagedObject) {
        persistentContainer.viewContext.delete(object)
        save()
    }
}
