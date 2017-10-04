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
    @NSManaged private var rawPool: String?
    @NSManaged private var rawCurrency: String?
    @NSManaged public var total: Double
    @NSManaged public var unpaid: Double
    @NSManaged public var unsold: Double
    @NSManaged public var paid24Hour: Double
    @NSManaged public var balance: Double
    @NSManaged public var name: String?
    @NSManaged public var updatedTimestamp: Date
    
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
