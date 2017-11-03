//
//  PortfolioWalletTableViewCell.swift
//  myminermonitor
//
//  Created by Aron on 15/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit
import CoreData

enum WalletRequestState : Int {
    case none
    case updating
    case error
    case success
}

class PortfolioWalletTableViewCell: UITableViewCell, WalletStatusDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var poolNameLabel: UILabel!
    @IBOutlet weak var walletLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var requestStatusImageView: UIImageView!
    @IBOutlet var walletLabelRowViews: [PortfolioWalletLabelRowView]!

    var requestState: WalletRequestState = .none {
        didSet {
            if requestState != oldValue {
                self.updateWalletRequestStateUI(for: requestState)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.requestStatusImageView.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.requestState = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.containerView.layer.cornerRadius = 15
        self.containerView.layer.masksToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(with wallet: Wallet) {
        wallet.delegate = self
        self.updateBalanceInfo(with: wallet)
        
        if wallet.isUpdating() {
            self.requestState = .updating
        }
        else if wallet.updateFailed {
            self.requestState = .error
        }
        else {
            self.requestState = .none
        }
    }
    
    func updateBalanceInfo(with wallet: Wallet) {
        poolNameLabel.text = wallet.pool.rawValue
        walletLabel.text = wallet.address
        
        if let date = wallet.updatedTimestamp as Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            lastUpdateLabel.text = "Last Update: " + dateFormatter.string(from: date)
        }
        
        var currentRowIndex = 0
        var walletLabelRow = walletLabelRowViews.first
        walletLabelRow?.isHidden = false
        func getNextWallet() {
            currentRowIndex += 1
            walletLabelRow = nil
            if walletLabelRowViews.count > currentRowIndex {
                walletLabelRow = walletLabelRowViews[currentRowIndex]
            }
        }
        func hideRemainingRows() {
            getNextWallet()
            if let walletLabelRow = walletLabelRow {
                walletLabelRow.isHidden = true
                hideRemainingRows()
            }
        }
        
        if wallet.currency != .bitcoin {
            assert(walletLabelRow != nil, "Wallet label row should not be nil!")
            if let walletLabelRow = walletLabelRow {
                updateBtcConvertionLabels(with: wallet, labelRowView: walletLabelRow)
            }
            getNextWallet()
            getConversionPrice(with: wallet)
        }
        
        assert(walletLabelRow != nil, "Wallet label row should not be nil!")
        update1HourEarningRate(with: wallet, labelRowView: walletLabelRow)
        getNextWallet()
        
        assert(walletLabelRow != nil, "Wallet label row should not be nil!")
        update24HourEarningRate(with: wallet, labelRowView: walletLabelRow)
        getNextWallet()
        
        assert(walletLabelRow != nil, "Wallet label row should not be nil!")
        updateConfirmedEarningsLabel(with: wallet, labelRowView: walletLabelRow)
        getNextWallet()
        
        assert(walletLabelRow != nil, "Wallet label row should not be nil!")
        updateTotalEarningsLabel(with: wallet, labelRowView: walletLabelRow)
        hideRemainingRows()
    }
    
    func updateBtcConvertionLabels(with wallet: Wallet, labelRowView: PortfolioWalletLabelRowView?) {
        labelRowView?.isHidden = false
        labelRowView?.fieldNameLabel.text = "BTC Value"
        labelRowView?.amountLabel.text = "-"
        labelRowView?.currencyLabel.text = Currency.bitcoin.rawValue
    }
    
    func updateConfirmedEarningsLabel(with wallet: Wallet, labelRowView: PortfolioWalletLabelRowView?) {
        labelRowView?.isHidden = false
        labelRowView?.fieldNameLabel.text = "Confirmed"
        labelRowView?.amountLabel.text = wallet.balance.toCurrencyString()
        labelRowView?.currencyLabel.text = wallet.currency.rawValue
    }
    
    func updateTotalEarningsLabel(with wallet: Wallet, labelRowView: PortfolioWalletLabelRowView?) {
        labelRowView?.isHidden = false
        labelRowView?.fieldNameLabel.text = "Total"
        labelRowView?.amountLabel.text = wallet.outstandingTotal.toCurrencyString()
        labelRowView?.currencyLabel.text = wallet.currency.rawValue
    }
    
    func update24HourEarningRate(with wallet: Wallet, labelRowView: PortfolioWalletLabelRowView?) {
        let profitIn24Hours = wallet.profitIn24Hours
        guard profitIn24Hours != 0 else {
            labelRowView?.isHidden = true
            return
        }
        
        labelRowView?.isHidden = false
        labelRowView?.fieldNameLabel.text = "Past 24 Hours"
        labelRowView?.amountLabel.text = profitIn24Hours.toCurrencyString()
        labelRowView?.currencyLabel.text = wallet.currency.rawValue
    }
    
    func update1HourEarningRate(with wallet: Wallet, labelRowView: PortfolioWalletLabelRowView?) {
        let profitIn1Hour = wallet.profitIn1Hour
        guard profitIn1Hour != 0 else {
            labelRowView?.isHidden = true
            return
        }
        
        labelRowView?.isHidden = false
        labelRowView?.fieldNameLabel.text = "Past 1 Hour"
        labelRowView?.amountLabel.text = profitIn1Hour.toCurrencyString()
        labelRowView?.currencyLabel.text = wallet.currency.rawValue
    }
    
    func walletDidBeginUpdating() {
        self.requestState = .updating
    }
    
    func walletDidFailToUpdate() {
        self.requestState = .error
    }
    
    func walletDidUpdate() {
        self.requestState = .success
    }
    
    func updateWalletRequestStateUI(for state: WalletRequestState) {
        self.requestStatusImageView.layer.removeAllAnimations()
        self.requestStatusImageView.transform = CGAffineTransform.identity
        self.requestStatusImageView.isHidden = false
        
        switch state {
        case .none:
            requestStatusImageView.isHidden = true
            break
        case .updating:
            requestStatusImageView.image = UIImage(named: "status_updating")
            requestStatusImageView.transform = CGAffineTransform.identity
            UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat], animations: {
                self.requestStatusImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }, completion: nil)
            break
        case .error:
            requestStatusImageView.image = UIImage(named: "status_error")
            break
        case .success:
            requestStatusImageView.image = UIImage(named: "status_success")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                if state == .success {
                    self.requestState = .none
                }
            })
            break
        }
    }
    
    func getConversionPrice(with wallet: Wallet) {
        guard let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/verge/") else {
            assert(false, "Could not create URL")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                //completionHandler()
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data)// as? [AnyObject: AnyObject] {
                    NSLog("\(jsonResponse)")
                    NSLog("")
//                    self.processResponse(jsonResponse)
//                    self.lastUpdated = Date()
//                    completionHandler()
              //  }
            } catch let parseError {
                print("parsing error: \(parseError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("raw response: \(responseString)")
                }
                //completionHandler()
            }
        }
        task.resume()
    }
}
