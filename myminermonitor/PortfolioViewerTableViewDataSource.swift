//
//  PortfolioViewerTableViewDataSource.swift
//  myminermonitor
//
//  Created by Aron on 15/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit
import CoreData

struct WalletOverview {
    var balance: Double = 0
    var totalUnpaid: Double = 0
    var totalPaid: Double = 0
    var totalEarned: Double = 0
    var totalPast1Hour: Double = 0
    var totalPast24Hours: Double = 0
}

protocol DataSourceObserver : class {
    func controllerDidChangeContent()
}

class PortfolioViewerTableViewDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    weak var updateDelegate: DataSourceObserver?
    var portfolioIdentifier: Int64?
    private var tableView: UITableView?
    
    private var _fetchedResultsController: NSFetchedResultsController<Wallet>?
    private var fetchedResultsController: NSFetchedResultsController<Wallet> {
        get {
            if _fetchedResultsController == nil {
                assert(portfolioIdentifier != nil, "portfolioIdentifier is nil!")
                let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "portfolioIdentifier == %lu", portfolioIdentifier ?? 0)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "address", ascending: true)]
                
                let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataStore.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
                
                frc.delegate = self
                
                do {
                    try frc.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
                
                _fetchedResultsController = frc
            }
            return _fetchedResultsController!
        }
    }
    
    func updateAllWallets() {
        guard let fetchedWallets = fetchedResultsController.fetchedObjects else {
            assert(false, "Fetched objects array is unexpectedly nil")
        }
        for wallet in fetchedWallets {
            wallet.update()
        }
    }
    
    func getWalletOverview() -> WalletOverview {
        var overview = WalletOverview()
        guard let fetchedWallets = fetchedResultsController.fetchedObjects else {
            assert(false, "Fetched objects array is unexpectedly nil")
        }
        for wallet in fetchedWallets {
            if wallet.currency == .bitcoin {
                overview.balance += wallet.balance
                overview.totalEarned += wallet.totalEarned
                overview.totalUnpaid += wallet.totalUnpaid
                overview.totalPaid += wallet.totalPaid
                overview.totalPast24Hours += wallet.profitIn24Hours
                overview.totalPast1Hour += wallet.profitIn1Hour
            }
            else {
                // TODO // convert to bitcoin and add
            }
        }
        return overview
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.tableView = tableView
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PoolWalletCell") as? PortfolioWalletTableViewCell,
            let wallet = self.wallet(at: indexPath) {
            cell.populate(with: wallet)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let wallet = self.wallet(at: indexPath) {
                DataStore.sharedInstance.removeEntity(wallet)
                tableView.reloadData()
            }
        }
    }
    
    func wallet(at indexPath: IndexPath) -> Wallet? {
        return self.fetchedResultsController.object(at: indexPath)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            if let cell = tableView?.cellForRow(at: indexPath!) as? PortfolioWalletTableViewCell,
                let wallet = self.wallet(at: indexPath!) {
                cell.updateBalanceInfo(with: wallet)
            }
            break
        case .move:
            tableView?.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
        updateDelegate?.controllerDidChangeContent()
    }
}
