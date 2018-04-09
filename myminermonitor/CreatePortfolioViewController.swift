//
//  CreatePortfolioViewController.swift
//  myminermonitor
//
//  Created by Aron on 09/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class CreatePortfolioViewController: UIViewController {

    @IBOutlet weak var portfolioAddressTextField: UITextField!
    @IBOutlet weak var portfolioNameTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    
    @IBAction func didPressCreate(_ sender: Any) {
        guard let portfolioAddress = portfolioAddressTextField.text,
            let portfolioName = portfolioNameTextField.text,
            portfolioAddress.isEmpty == false,
            portfolioName.isEmpty == false else {
            return
        }
        let _ = DataStore.sharedInstance.insertNewPortfolio(for: portfolioAddress, with: portfolioName)
        DataStore.sharedInstance.save()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
