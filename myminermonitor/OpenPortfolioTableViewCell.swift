//
//  OpenPortfolioTableViewCell.swift
//  myminermonitor
//
//  Created by Aron on 06/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class OpenPortfolioTableViewCell: UITableViewCell {

    @IBOutlet weak var portfolioNameLabel: UILabel!
    weak var portfolio: Portfolio? {
        didSet {
            setupCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    private func setupCell() {
        self.portfolioNameLabel.text = portfolio?.name ?? "No name set"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
