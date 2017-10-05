//
//  PortfolioViewerViewController.swift
//  myminermonitor
//
//  Created by Aron on 15/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class PortfolioViewerViewController: UIViewController, UITableViewDelegate, DataSourceObserver {

    var portfolioIdentifier: Int64? {
        didSet {
            portfolioViewerDataSource.portfolioIdentifier = portfolioIdentifier
        }
    }
    @IBOutlet weak var pastHourEarningsLabel: UILabel!
    @IBOutlet weak var past24HourEarningsLabel: UILabel!
    @IBOutlet weak var totalEarningsLabel: UILabel!
    @IBOutlet weak var totalEarningsLocalizedLabel: UILabel!
    @IBOutlet weak var btcExchangeRateLabel: UILabel!
    @IBOutlet weak var totalEarningsLocalizedAmountLabel: UILabel!
    @IBOutlet weak var portfolioViewerDataSource: PortfolioViewerTableViewDataSource!
    
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = NSLocale.current
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pastHourEarningsLabel.text = "0"
        past24HourEarningsLabel.text = "0"
        totalEarningsLabel.text = "0"
        portfolioViewerDataSource.updateDelegate = self
        updateOverviewLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assert(portfolioIdentifier != nil, "Portfolio Identifier is nil!")
    }

    @IBAction func didPressAddWalletButton(_ sender: Any) {
        guard let identifier = portfolioIdentifier else {
            return
        }
        
        let createWalletVC = UIStoryboard(name: "CreateWallet", bundle: nil).instantiateInitialViewController() as! CreateWalletViewController
        createWalletVC.portfolioIdentifier = identifier
        let navController = UINavigationController(rootViewController: createWalletVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func didPressRefreshWallets(_ sender: Any) {
        portfolioViewerDataSource.updateAllWallets()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        guard let wallet = self.portfolioViewerDataSource.wallet(at: indexPath) else {
                // TODO: Alert
                return
        }
        
        wallet.update()
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func controllerDidChangeContent() {
        updateOverviewLabels()
    }
    
    func updateOverviewLabels() {
        let overview = portfolioViewerDataSource.getWalletOverview()
        pastHourEarningsLabel.text = overview.totalPast1Hour.toCurrencyString()
        past24HourEarningsLabel.text = overview.totalPast24Hours.toCurrencyString()
        totalEarningsLabel.text = overview.totalEarned.toCurrencyString()
        
        CryptoPriceIndex.sharedInstance.getBitcoinPriceForCurrentLocale { (price, symbol) in
            self.totalEarningsLocalizedLabel.text = "Total Earnings (\(symbol))"
            let localizedPriceString = self.numberFormatter.string(from: NSNumber(value: price))!
            self.btcExchangeRateLabel.text = "1 BTC = " + localizedPriceString
            self.totalEarningsLocalizedAmountLabel.text = self.numberFormatter.string(from: NSNumber(value: overview.totalEarned * price))!
        }
    }
}
