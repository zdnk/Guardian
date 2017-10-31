//
//  ViewController.swift
//  GuardianExample
//
//  Created by Topic, Zdenek on 30/10/2017.
//  Copyright © 2017 Zdenek Topic. All rights reserved.
//

import UIKit
import Guardian

class ViewController: UIViewController {

    let guardian = Guardian()
    
    @IBOutlet weak var statusLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        guardian.defaultReason = "bitch"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func biometric() {
        guardian.authenticate(using: .biometry) { (result) in
            print(result)
        }
    }
    
    @IBAction func passcode() {
        guardian.authenticate(using: .biometryOrPasscode) { (result) in
            print(result)
        }
    }
    
}

