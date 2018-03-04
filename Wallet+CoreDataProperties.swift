//
//  Wallet+CoreDataProperties.swift
//  myminermonitor
//
//  Created by Aron on 08/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import Foundation
import CoreData


extension Wallet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Wallet> {
        return NSFetchRequest<Wallet>(entityName: "Wallet")
    }

    @NSManaged public var portfolioIdentifier: Int64
    @NSManaged public var address: String?
    @NSManaged private var rawActiveMiners: String?
    @NSManaged private var rawPool: String?
    @NSManaged private var rawCurrency: String?
    @NSManaged public var totalPaid: Double
    @NSManaged public var totalUnpaid: Double
    @NSManaged public var balance: Double
    @NSManaged public var unsold: Double
    @NSManaged public var totalEarned: Double
    @NSManaged public var profitIn1Hour: Double
    @NSManaged public var profitIn24Hours: Double
    @NSManaged public var name: String?
    @NSManaged public var updatedTimestamp: NSDate?
    
    var activeMiners: [String] {
        get {
            guard let rawActiveMiners = rawActiveMiners else {
                return []
            }
            return rawActiveMiners.components(separatedBy: "||")
        }
        set {
            if newValue.count == 0 {
                rawActiveMiners = nil
            }
            else {
                rawActiveMiners = newValue.joined(separator: "||")
            }
        }
    }
    
    var pool: Pool {
        get {
            if let rawPool = rawPool {
                return Pool(safeRawValue: rawPool)
            }
            else {
                return .unknown
            }
        }
        set {
            rawPool = newValue.rawValue
        }
    }
    
    var currency: Currency {
        get {
            if let rawCurrency = rawCurrency {
                return Currency(safeRawValue: rawCurrency)
            }
            else {
                return .unknown
            }
        }
        set {
            rawCurrency = newValue.rawValue
        }
    }
}
