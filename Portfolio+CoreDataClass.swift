//
//  Portfolio+CoreDataClass.swift
//  myminermonitor
//
//  Created by Aron on 08/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import Foundation
import CoreData

@objc(Portfolio)
public class Portfolio: NSManagedObject {

    class func allPortfolios() -> [Portfolio] {
        let fetchRequest: NSFetchRequest<Portfolio> = Portfolio.fetchRequest()
        let context = DataStore.sharedInstance.persistentContainer.viewContext
        do {
            let allPortfolios = try context.fetch(fetchRequest)
            return allPortfolios
        } catch {
            // TODO error catch
        }
        return []
    }
    
    func updateAllWallets(_ completionHandler: ((_ result: WalletUpdateResult)->())?) {
        Wallet.updateAllWallets { (walletUpdateResult, activeMiners) in
            guard walletUpdateResult == .success else {
                completionHandler?(walletUpdateResult)
                return
            }
            
            self.lastFullUpdateTime = NSDate()
            if let latestMinerCount = activeMiners?.count {
                if self.downtimeMinimumMiners > latestMinerCount {
                    self.downtimeFailedMinersCountInARow += 1
                    self.sendMinerDowntimeWarningIfNecessary(latestMinerCount: latestMinerCount)
                } else {
                    self.downtimeFailedMinersCountInARow = 0
                }
            } else {
                self.downtimeFailedMinersCountInARow = 0
            }
            
            self.sendDailyReportIfNecessary()
            
            // TODO expand this save
            try? self.managedObjectContext?.save()
            completionHandler?(walletUpdateResult)
        }
    }
    
    func sendDailyReportIfNecessary(_ force: Bool = false) {
        if force || shouldSendDailyReport() {
            let walletName = name ?? "Wallet"
            Notifications.shared.sendLocalNotification(title: walletName + " Daily 24h Report", body: dailyReportNotificationBody())
            dailyReportTime = NSDate(timeIntervalSince1970: dailyReportTime.timeIntervalSince1970 + 60 * 60 * 24)
        }
    }
    
    func sendMinerDowntimeWarningIfNecessary(latestMinerCount: Int) {
        NSLog("Downtime count: \(downtimeFailedMinersCountInARow)")
        if self.downtimeFailedMinersCountInARow == 3 {
            let walletName = name ?? "Wallet"
            Notifications.shared.sendLocalNotification(title: walletName + " Downtime Warning", body: minerDowntimeWarningNotificationBody(latestMinerCount: latestMinerCount))
        }
    }
    
    private func shouldSendDailyReport() -> Bool {
        guard dailyReportsEnabled else {
            return false
        }
        guard let lastFullUpdateTime = lastFullUpdateTime else {
            return false
        }
        
        return lastFullUpdateTime.timeIntervalSince(dailyReportTime as Date) > 0
    }
    
    private func dailyReportNotificationBody() -> String {
        let allWallets = getAllWallets()
        let fullOverview = WalletOverview(wallets: allWallets)
        
        let allWallets24HourSummary = allWallets.compactMap { $0.getLast24HoursWalletSummary() }
        let dailyChangeOverview = WalletOverview(walletData: allWallets24HourSummary)
        let totalPaidIn24Hours = allWallets24HourSummary.compactMap { $0.totalPaid }.reduce(0, +)
        
        let last24HoursString = "Earnings: \t\t" + dailyChangeOverview.totalEarned.toCurrencyString() + " BTC"
        let hourlyRateString = "\nHourly Rate: \t" + (dailyChangeOverview.totalEarned / 24).toCurrencyString() + " BTC"
        let payoutsIn24HoursString = "\nPayouts: \t\t" + totalPaidIn24Hours.toCurrencyString() + " BTC"
        let balanceString = "\nTotal Unpaid: \t" + fullOverview.totalUnpaid.toCurrencyString() + " BTC"
        return last24HoursString + hourlyRateString + payoutsIn24HoursString + balanceString
    }
    
    private func minerDowntimeWarningNotificationBody(latestMinerCount: Int) -> String {
        let topLine = "One or more miners may have gone offline."
        
        let latestMinerInfo: String
        if latestMinerCount == 1 {
            latestMinerInfo = "\nAt the last update 1 miner was seen"
        } else {
            latestMinerInfo = "\nAt the last update only \(latestMinerCount) miners were seen."
        }
        
        let lastMinerSeenInfo: String
        
//        "At the last update only 0 miners were seen"
//        "The last time 4 miners were seen was at 10am"
        
        return topLine + latestMinerInfo //+ lastMinerSeenInfo
    }
}
