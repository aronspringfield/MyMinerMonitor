//
//  PortfolioPickerViewController.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class PortfolioPickerViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    @IBAction func informationButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Info", message: "This is a work in progress!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func addWalletButtonPressed(_ sender: AnyObject?) {
        let navController = UIStoryboard(name: "CreatePortfolio", bundle: nil).instantiateInitialViewController()!
        navController.modalPresentationStyle = .formSheet
        self.present(navController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        guard let pickerSection = PortolioPickerSections(rawValue: indexPath.section) else {
            assert(false, "Failed to find matching tableview section")
            return
        }
        
        switch pickerSection {
        case .open:
            guard let dataSource = tableView.dataSource as? PortfolioPickerDataSource,
                let portfolio = dataSource.portfolio(at: indexPath) else {
                    assert(false, "Failed to get tableView's dataSource")
                    return
            }
            let portfolioViewer = UIStoryboard(name: "PortfolioViewer", bundle: nil).instantiateInitialViewController() as! PortfolioViewerViewController
            portfolioViewer.portfolio = portfolio
            self.navigationController?.pushViewController(portfolioViewer, animated: true)
            
            break
        case .create:
            addWalletButtonPressed(cell)
            break
        }
    }
}
