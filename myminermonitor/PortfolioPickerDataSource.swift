//
//  PortfolioPickerDataSource.swift
//  myminermonitor
//
//  Created by Aron on 07/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit
import CoreData

enum PortolioPickerSections : Int {
    case open
    case create
}

class PortfolioPickerDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    private var tableView: UITableView?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Portfolio> = {
        let fetchRequest: NSFetchRequest<Portfolio> = Portfolio.fetchRequest()

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataStore.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        return fetchedResultsController
    }()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.tableView = tableView
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let pickerSection = PortolioPickerSections(rawValue: section) else {
            assert(false, "Failed to find matching tableview section")
            return 0
        }
        
        switch pickerSection {
        case .open:
            return fetchedResultsController.fetchedObjects?.count ?? 0
        case .create:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let pickerSection = PortolioPickerSections(rawValue: indexPath.section) else {
            assert(false, "Failed to find matching tableview section")
            return UITableViewCell()
        }
        
        switch pickerSection {
        case .open:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "OpenPortfolioCell") as? OpenPortfolioTableViewCell,
                let portfolio = self.portfolio(at: indexPath) {
                cell.portfolio = portfolio
                return cell
            }
        case .create:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CreatePortfolioCell") {
                return cell
            }
        }
        
        assert(false, "Failed to configure tableview cell")
        return UITableViewCell()
    }
    
    func portfolio(at indexPath: IndexPath) -> Portfolio? {
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
            tableView?.reloadRows(at: [indexPath!], with: .fade)
            break
        case .move:
            tableView?.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }
}
