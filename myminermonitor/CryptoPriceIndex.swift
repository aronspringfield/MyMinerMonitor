//
//  CryptoPriceIndex.swift
//  myminermonitor
//
//  Created by Aron on 25/09/2017.
//  Copyright © 2017 Aron Springfield. All rights reserved.
//

import UIKit

class CryptoPriceIndex {

    static let sharedInstance = CryptoPriceIndex()
    
    private let updateInterval = TimeInterval(exactly: 60 * 60)!
    private var btcPriceIndex = [String: Double]()
    var lastUpdated: Date = Date.distantPast
    
    func getBitcoinPriceForCurrentLocale(_ response: @escaping (Double, String) -> Void) {
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdated)
        if timeSinceUpdate > updateInterval || localBtcPrice() == 0 {
            updatePrices({
                DispatchQueue.main.async {
                    response(self.localBtcPrice(), NSLocale.current.currencySymbol ?? "?")
                }
            })
        }
        else {
            response(self.localBtcPrice(), NSLocale.current.currencySymbol ?? "?")
        }
    }
    
    private func localBtcPrice() -> Double {
        if let currencyCode = NSLocale.current.currencyCode,
            let price = btcPriceIndex[currencyCode] {
            return price
        }
        return 0
    }
    
    func updatePrices(_ completionHandler: @escaping () -> Void) {
        guard let url = URL(string: "https://blockchain.info/ticker") else {
            assert(false, "Could not create URL")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completionHandler()
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject] {
                    self.processResponse(jsonResponse)
                    self.lastUpdated = Date()
                }
            } catch let parseError {
                print("parsing error: \(parseError)")
                let responseString = String(data: data, encoding: .utf8)
                print("raw response: \(responseString)")
            }
            completionHandler()
        }
        task.resume()
    }
    
    private func processResponse(_ response: [String: AnyObject]) {
        guard let currencyCode = NSLocale.current.currencyCode else {
            assert(false, "Unable to find currency code")
            return
        }
        guard let priceIndexObject = response[currencyCode] as? [String : AnyObject],
        let price = priceIndexObject["15m"] as? NSNumber else {
            assert(false, "Cannot find price for currency code: \(currencyCode)")
            return
        }
        
        btcPriceIndex[currencyCode] = price.doubleValue
    }
}
