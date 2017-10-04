//
//  WalletSnapshot+CoreDataProperties.swift
//  myminermonitor
//
//  Created by Aron on 04/10/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//
//

import Foundation
import CoreData


extension WalletSnapshot {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WalletSnapshot> {
        return NSFetchRequest<WalletSnapshot>(entityName: "WalletSnapshot")
    }

    @NSManaged public var timestamp: NSDate?
    @NSManaged public var unsold: Double
    @NSManaged public var unpaid: Double
    @NSManaged public var total: Double
    @NSManaged public var walletIdentifier: String?
    @NSManaged public var paid24Hour: Double
    @NSManaged public var balance: Double

}
