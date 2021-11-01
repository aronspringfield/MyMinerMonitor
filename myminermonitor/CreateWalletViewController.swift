//
//  CreateWalletViewController.swift
//  myminermonitor
//
//  Created by Aron on 17/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class CreateWalletViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var portfolioIdentifier: Int64?
    var prefillAddress: String?
    @IBOutlet weak var poolNameTextField: UITextField!
    var poolPickerView: UIPickerView!
    @IBOutlet weak var walletAddressLabel: UITextField!
    
    var pickerData: [Pool] = [
        .unknown,
        .yiimp,
        .zpool,
        .hashRefinery,
        .aHashPool,
        .blazePool,
        .zergPool,
        .mineMoney,
        .phiPhiPool,
        .blockMasters
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        poolPickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 200))
        poolPickerView.delegate = self
        poolPickerView.dataSource = self
        poolNameTextField.inputView = poolPickerView
        
        if let prefillAddress = prefillAddress {
            walletAddressLabel.text = prefillAddress
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        poolNameTextField.text = pickerData[row].rawValue
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    @IBAction func didPressCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressQrCode(_ sender: Any) {
    }
    
    @IBAction func didPressCopyFromClipboard(_ sender: Any) {
        walletAddressLabel.text = UIPasteboard.general.string
    }
    
    @IBAction func didPressCreate(_ sender: Any) {
        guard let identifier = portfolioIdentifier,
            let poolName = poolNameTextField.text,
            let pool = Pool(rawValue: poolName),
            pool != .unknown,
            let walletAddress = walletAddressLabel.text else {
                return
        }
        
        let wallet = DataStore.sharedInstance.insertNewWallet(for: identifier,
                                                              pool: pool,
                                                              address: walletAddress)
        DataStore.sharedInstance.save()
        self.dismiss(animated: true) {
            wallet.update()
        }
    }
}
