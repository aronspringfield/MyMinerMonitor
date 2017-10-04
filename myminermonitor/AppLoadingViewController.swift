//
//  AppLoadingViewController.swift
//  myminermonitor
//
//  Created by Aron on 05/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class AppLoadingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()


    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            DataStore.sharedInstance.loadStore { (success) in
                if success {
                    let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
                    self.present(mainVC, animated: true, completion: {
                    })
                }
                else {
                    let alertController = UIAlertController(title: "Whoops!", message: "Something has gone wrong. Our data has failed to load. If this persists, consider reinstalling the app.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }

    }
}

