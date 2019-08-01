//
//  CurrencyManager.swift
//  CurrencyConvert
//
//  Created by Kem Belderol on 01/08/2019.
//  Copyright © 2019 Krats. All rights reserved.
//

import Foundation
import Alamofire

enum Currency: String {
    case EUR
    case USD
    case JPY
}

protocol CurrencyManagerProtocol {
    func updateUserBalance()
}

class CurrencyManager: NSObject {
    
    // For Testing: This resets all defaults if new user "signs in"
    // MARK: - Variables
    fileprivate let userID: String = "firstUserID"
    fileprivate var defaultFreeInstance: Int = 5
    var delegate: CurrencyManagerProtocol?
    
    // MARK: - Conversion
    func convertCurrency(with amount: Double, from: Currency, to: Currency, completed: @escaping (Bool, String) -> Void) {
        if let currentBalanceState: (Bool, String) = self.checkIfBalanceIsPositive(with: from, amount: amount) {
            completed(currentBalanceState.0, currentBalanceState.1)
            return
        }
        guard let url = URL(string: "http://api.evp.lt/currency/commercial/exchange/\(amount)-\(from.rawValue)/\(to.rawValue)/latest")  else {
            completed(false, "Error transferring funds")
            return
        }
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).validate().responseJSON { response in
            guard let result = response.result.value as? [String: Any] else {
                completed(false, "Error transferring funds")
                return
            }
            let currentBalanceFromCurrency = self.retrieveCurrentBalance(from: from)
            if let currency = Currency(rawValue:result["currency"] as! String), let convertedAmount = Double(result["amount"] as! String) {
                var subtractedAmount: Double = amount
                self.saveUpdatedAccount(from: [from: (currentBalanceFromCurrency - subtractedAmount)], to: [currency: convertedAmount + self.retrieveCurrentBalance(from: currency)], completed: {
                    if self.retrieveFreeTransferInstance() > 0 {
                        completed(true, "You have converted \(amount.rounded()) \(from.rawValue) to \(convertedAmount) \(currency.rawValue).")
                    } else {
                        subtractedAmount += amount.conversion()
                        completed(true, "You have converted \(amount.rounded()) \(from.rawValue) to \(convertedAmount) \(currency.rawValue). Commission Fee - \(amount.conversion().rounded()) \(from.rawValue).")
                    }
                })
            }
        }
    }
    
    // MARK: - Saving Updated Balances
    func saveUpdatedAccount(from balance: [Currency: Double], to: [Currency: Double], completed: () -> Void) {
        if balance.keys.first == to.keys.first || balance.values.first! < 0.0 {
            return
        }
        UserDefaults.standard.set(balance.values.first, forKey: self.retrieveCurrentKey(from: balance.keys.first!))
        UserDefaults.standard.set(to.values.first, forKey: self.retrieveCurrentKey(from: to.keys.first!))
        self.delegate?.updateUserBalance()
        completed()
    }
    
    // MARK: - Checking Positive Balance
    func checkIfBalanceIsPositive(with currency: Currency, amount: Double) -> (Bool, String)? {
        
        let freeInstance: Int = self.retrieveFreeTransferInstance()
        let transactionAmount = (freeInstance > 0) ? 0 : (amount + amount.conversion())

        let currentCurrencyAmount = self.retrieveCurrentBalance(from: currency)
        
        if (currentCurrencyAmount - transactionAmount) < 0.0 {
            return (false, "Current \(self.retrievCurrencyText(from: currency)) balance must not reach negative")
        }
        return nil
    }
    
    // MARK: - Retrieve Free Transaction
    func retrieveFreeTransferInstance() -> Int {
        if let freeInstance = UserDefaults.standard.value(forKey: self.userID) as? Int {
            UserDefaults.standard.set((freeInstance - 1), forKey: self.userID)
            return freeInstance
        }
        UserDefaults.standard.set(self.defaultFreeInstance, forKey: self.userID)
        return self.defaultFreeInstance
    }

    // MARK: - Retrieve Current Balance
    func retrieveCurrentBalance(from currency: Currency) -> Double {
        if let balance = UserDefaults.standard.value(forKey: self.retrieveCurrentKey(from: currency)) as? Double {
            return balance
        } else {
            switch currency {
            case .EUR:
                return 1000
            case .JPY, .USD:
                return 0
            }
        }
    }
    
    func retrieveAvailableCurrencies() -> [Currency] {
        return [.EUR, .USD, .JPY]
    }
    
    func retrieveCurrentKey(from currency: Currency) -> String {
        return retrievCurrencyText(from: currency) + self.userID
    }
    
    func retrievCurrencyText(from currency: Currency) -> String {
        switch currency {
        case .EUR:
            return "Euro"
        case .USD:
            return "US Dollar"
        case .JPY:
            return "Japanese Yen"
        }
    }
}

// MARK: - Extensions
extension Double {
    
    func conversion() -> Double {
        return self * 0.07
    }
    
}
