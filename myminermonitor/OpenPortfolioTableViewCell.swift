//
//  OpenPortfolioTableViewCell.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class OpenPortfolioTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var twentyFourHourEarningsLabel: UILabel!
    
    weak var portfolio: Portfolio? {
        didSet {
            setupCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.nameLabel.text = "no name set"
        self.addressLabel.text = "no address set"
        self.balanceLabel.text = "-"
        self.twentyFourHourEarningsLabel.text = "-"
    }
    
    private func setupCell() {
        guard let portfolio = portfolio else {
            return
        }
        
        let overview = WalletOverview(wallets: portfolio.getAllWallets())
        
        self.nameLabel.text = portfolio.name
        self.addressLabel.text = portfolio.address        
        self.balanceLabel.text =  overview.balance.toCurrencyString()
        self.twentyFourHourEarningsLabel.text = overview.totalPast24Hours.toCurrencyString()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
