//
//  ViewController.swift
//  CurrencyConvert
//
//  Created by Kem Belderol on 31/07/2019.
//  Copyright © 2019 Krats. All rights reserved.
//

import UIKit

class ConverterViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var currencyPickerView: UIPickerView!
    @IBOutlet weak var fromPickerView: UIPickerView!
    @IBOutlet weak var toPickerView: UIPickerView!
    
    @IBOutlet var currencyPickerViewCollection: [UIPickerView]!
    
    @IBOutlet weak var currentBalanceInfoLabel: UILabel!
    @IBOutlet weak var currentBalanceAmountLabel: UILabel!
    @IBOutlet weak var transferSuccessInfoLabel: UILabel!
    
    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var totalCommissionButton: UIButton!
    @IBOutlet weak var transferActionButton: BorderedButton!
    //Constraints
    
    let currencyManager: CurrencyManager = CurrencyManager()
    var currentFromCurrency: Currency = .EUR
    var currentToCurrency: Currency = .EUR
    var selectedCurrencyBalance: Currency = .EUR
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.currencyManager.delegate = self
        self.setupViews()
    }
    
    // MARK: - Setup PickerView
    fileprivate func setupViews() {
        self.currencyPickerViewCollection.forEach({
            $0.dataSource = self
            $0.delegate = self
        })
        self.amountTextField.delegate = self
        let defaultBalanceAmount = self.currencyManager.retrieveCurrentBalance(from: .EUR)
        self.currentBalanceAmountLabel.text = "\(defaultBalanceAmount) \(Currency.EUR.rawValue)"
    }
    
    @IBAction func transferCurrencyTouchedUp(_ sender: BorderedButton) {
        guard let amountText = self.amountTextField.text, let amount = Double(amountText) else {return}
        self.currencyManager.convertCurrency(with: amount, from: self.currentFromCurrency, to: self.currentToCurrency) { (success, message) in
            if success {
                self.transferSuccessInfoLabel.text = message
            } else {
                self.presentAlertController(title: "Error", message: message)
            }
        }
    }
    
    @IBAction func totalCommissionTouchedUp(_ sender: UIButton) {
        let totalComission = UserDefaults.standard.value(forKey: self.currencyManager.commissionFeesKey + self.selectedCurrencyBalance.rawValue) as? Double ?? 0.0
        
        self.presentAlertController(title: "Total Commission Fees", message: "You have a total of \(totalComission.rounded()) in commission fees for \(self.selectedCurrencyBalance) account")
    }
    
    func presentAlertController(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .destructive, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UITextFieldDelegate
extension ConverterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - CurrencyManagerProtocol
extension ConverterViewController: CurrencyManagerProtocol {
    
    func updateUserBalance() {
        let currentAmount = self.currencyManager.retrieveCurrentBalance(from: selectedCurrencyBalance)
        self.currentBalanceAmountLabel.text = "\(currentAmount.rounded()) \(selectedCurrencyBalance.rawValue)"
        self.currentBalanceInfoLabel.text = "Current Balance for \(selectedCurrencyBalance.rawValue) Account"
    }
    
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension ConverterViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyManager.retrieveAvailableCurrencies().count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let currentCurrency = self.currencyManager.retrieveAvailableCurrencies()[row]
        switch pickerView {
        case self.currencyPickerView:
            let currentBalance: Double = self.currencyManager.retrieveCurrentBalance(from: currentCurrency)
            self.selectedCurrencyBalance = currentCurrency
            self.currentBalanceAmountLabel.text = "\(currentBalance.rounded()) \(currentCurrency.rawValue)"
            self.currentBalanceInfoLabel.text = "Current Balance for \(currentCurrency.rawValue) Account"
        case self.fromPickerView:
            self.currentFromCurrency = currentCurrency
        case self.toPickerView:
            self.currentToCurrency = currentCurrency
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let currency = self.currencyManager.retrieveAvailableCurrencies()[row]
        let currencyText: String = (pickerView == self.currencyPickerView) ? self.currencyManager.retrievCurrencyText(from: currency) : currency.rawValue
        
        pickerLabel.attributedText = NSAttributedString(string: currencyText, attributes: [NSAttributedString.Key.font:UIFont(name: "AvenirNext-Medium", size: 18.0)!, NSAttributedString.Key.foregroundColor: UIColor.white])
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    
}

