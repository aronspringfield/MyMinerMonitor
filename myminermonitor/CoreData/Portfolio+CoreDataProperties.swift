//
//  Portfolio+CoreDataProperties.swift
//  myminermonitor
//
//  Created by Aron on 08/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import Foundation
import CoreData

extension Portfolio {
    @NSManaged public var identifier: Int64
    @NSManaged public var address: String?
    @NSManaged public var dailyReportsEnabled: Bool
    @NSManaged private var rawDailyReportTime: NSDate?
    @NSManaged public var downtimeFailedMinersCountInARow: Int32
    @NSManaged private var rawDowntimeMinimumMiners: Int32
    @NSManaged public var downtimeWarningsEnabled: Bool
    @NSManaged public var name: String?
    @NSManaged public var lastFullUpdateTime: NSDate?
    @NSManaged public var rawWallets: NSObject?
    
    var dailyReportTime: NSDate {
        get {
            if let rawDailyReportTime = rawDailyReportTime {
                return rawDailyReportTime
            }
            else {
                var components = DateComponents()
                components.hour = 10
                components.minute = 30
                let calendar = NSCalendar(calendarIdentifier: .gregorian)
                if let date = calendar?.date(from: components) {
                    self.rawDailyReportTime = date as NSDate
                    return date as NSDate
                }
                return NSDate()
            }
        }
        set {
            rawDailyReportTime = newValue
        }
    }
    
    var downtimeMinimumMiners: Int32 {
        get {
            if rawDowntimeMinimumMiners == 0 {
                rawDowntimeMinimumMiners = 1
            }
            return rawDowntimeMinimumMiners
        }
        set {
            rawDowntimeMinimumMiners = newValue
        }
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Portfolio> {
        return NSFetchRequest<Portfolio>(entityName: "Portfolio")
    }

    @nonobjc public func getAllWallets() -> [Wallet] {
        guard let address = address else {
            return []
        }
        let context = DataStore.sharedInstance.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "address == %@", address)

        do {
            let result = try context.fetch(fetchRequest)
            return result
        }
        catch {
            return []
        }
    }
}
