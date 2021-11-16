//
//  PortfolioViewerViewController.swift
//  myminermonitor
//
//  Created by Aron on 15/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class PortfolioViewerViewController: UIViewController, UITableViewDelegate, DataSourceObserver {

    var portfolio: Portfolio? {
        didSet {
            if let portfolio = portfolio {
                portfolioViewerDataSource.portfolioIdentifier = portfolio.identifier
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            portfolioViewerDataSource?.tableView = tableView
        }
    }
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var totalUnpaidLabel: UILabel!
    @IBOutlet weak var totalEarnedLabel: UILabel!
    @IBOutlet weak var pastHourEarningsLabel: UILabel!
    @IBOutlet weak var past24HoursEarningsLabel: UILabel!
    @IBOutlet weak var btcExchangeRateLabel: UILabel!
    @IBOutlet weak var totalEarningsLocalizedAmountLabel: UILabel!
    @IBOutlet weak var activeMinersListLabel: UILabel!
    @IBOutlet weak var portfolioViewerDataSource: PortfolioViewerTableViewDataSource! {
        didSet {
            portfolioViewerDataSource.tableView = tableView
        }
    }
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = NSLocale.current
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        balanceLabel.text = "0"
        totalUnpaidLabel.text = "0"
        totalEarnedLabel.text = "0"
        pastHourEarningsLabel.text = "0"
        past24HoursEarningsLabel.text = "0"
        activeMinersListLabel.text = "-"
        tableView.separatorStyle = .none
        portfolioViewerDataSource.updateDelegate = self
        updateOverviewLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assert(portfolio != nil, "Portfolio is nil!")
    }

    @IBAction func didPressAddWalletButton(_ sender: Any) {
        guard let portfolio = portfolio else {
            return
        }
        
        let createWalletVC = UIStoryboard(name: "CreateWallet", bundle: nil).instantiateInitialViewController() as! CreateWalletViewController
        createWalletVC.portfolioIdentifier = portfolio.identifier
        createWalletVC.prefillAddress = portfolio.address
        let navController = UINavigationController(rootViewController: createWalletVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func didPressRefreshWallets(_ sender: Any) {
        portfolio?.updateAllWallets(nil)
    }
    
    @IBAction func didPressSettings(_ sender: Any) {
        let settingsViewController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! SettingsViewController
        settingsViewController.portfolio = self.portfolio
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        guard let wallet = self.portfolioViewerDataSource.wallet(at: indexPath) else {
                // TODO: Show Warning Alert
                return
        }
        
        wallet.update()
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func controllerDidChangeContent() {
        updateOverviewLabels()
    }
    
    func updateOverviewLabels() {
        let overview = portfolioViewerDataSource.getWalletOverview()
        balanceLabel.text = overview.balance.toCurrencyString()
        totalUnpaidLabel.text = overview.totalUnpaid.toCurrencyString()
        totalEarnedLabel.text = overview.totalEarned.toCurrencyString()
        pastHourEarningsLabel.text = overview.totalPast1Hour.toCurrencyString()
        past24HoursEarningsLabel.text = overview.totalPast24Hours.toCurrencyString()
        if overview.activeMiners.count > 0 {
            activeMinersListLabel.text = overview.activeMiners.joined(separator: "\n")
        } else {
            activeMinersListLabel.text = "-"
        }
        
        // TODO: refactor this label toggle
//        CryptoPriceIndex.sharedInstance.getBitcoinPriceForCurrentLocale { (price, symbol) in
//            self.totalEarningsLocalizedLabel.text = "Total Earnings (\(symbol))"
//            let localizedPriceString = self.numberFormatter.string(from: NSNumber(value: price))!
//            self.btcExchangeRateLabel.text = "1 BTC = " + localizedPriceString
//            self.totalEarningsLocalizedAmountLabel.text = self.numberFormatter.string(from: NSNumber(value: overview.totalEarned * price))!
//        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions = [UITableViewRowAction]()
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            if let wallet = self.portfolioViewerDataSource.wallet(at: indexPath) {
                DataStore.sharedInstance.removeEntity(wallet)
                tableView.reloadData()
            }
        }
        actions.append(deleteAction)
        
        let refreshAction = UITableViewRowAction(style: .normal, title: "Refresh") { (action, indexPath) in
            if let wallet = self.portfolioViewerDataSource.wallet(at: indexPath) {
                wallet.update()
            }
        }
        actions.append(refreshAction)
        
        return actions
    }
}
