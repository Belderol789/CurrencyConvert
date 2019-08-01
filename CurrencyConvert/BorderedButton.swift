//
//  BorderedButton.swift
//  CurrencyConvert
//
//  Created by Kem Belderol on 31/07/2019.
//  Copyright © 2019 Krats. All rights reserved.
//

import UIKit

class BorderedButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initXibs()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initXibs()
    }
    
    fileprivate func initXibs() {
        self.layer.cornerRadius = 6.0
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
    }

}
