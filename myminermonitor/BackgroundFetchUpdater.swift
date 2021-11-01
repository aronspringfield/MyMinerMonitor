//
//  BackgroundFetcher.swift
//  myminermonitor
//
//  Created by Aron Springfield on 17/05/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

class BackgroundFetcher: NSObject {

    class func update(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("Beginning background fetch")
        
        let dispatchGroup = DispatchGroup()
        var globalFetchResult = UIBackgroundFetchResult.noData
        
        let updateGlobalFetchState = { (walletUpdateResult: WalletUpdateResult) in
            switch (globalFetchResult, walletUpdateResult) {
            case (.newData, _):
                break
            case (.noData, .success),
                 (.noData, .partialSuccess):
                globalFetchResult = .newData
            case (.noData, .failed):
                globalFetchResult = .failed
            case (.failed, .success),
                 (.failed, .partialSuccess):
                globalFetchResult = .newData
            default:
                break
            }
        }
        
        let executeFetch = {
            for portfolio in Portfolio.allPortfolios() {
                dispatchGroup.enter()
                portfolio.updateAllWallets({ (updateResult) in
                    updateGlobalFetchState(updateResult)
                    dispatchGroup.leave()
                })
            }
        }
        
        DataStore.sharedInstance.loadStore { (success) in
            if success {
                executeFetch()
                dispatchGroup.notify(queue: .main) {
                    NSLog("background fetch finished with result: \(globalFetchResult.rawValue)")
                    completionHandler(globalFetchResult)
                }
            }
            else {
                NSLog("background fetch failed")
                completionHandler(.failed)
            }
        }
    }
}
