//
//  IPInputController.swift
//  WebRTC-Demo
//
//  Created by Ke Ma on 2019-03-04.
//  Copyright © 2019 Stas Seldin. All rights reserved.
//

import UIKit

class IPInputController: UIViewController {
	
	@IBOutlet var IPInputField: UITextField!
	
	@IBAction func continueTapped(_ sender: Any) {
		guard let ipAddress = IPInputField.text else { return }
		onContinuePerformed?(ipAddress)
	}
	
	var onContinuePerformed: ((String) -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "WebRTC Demo"
		// Default IP address
		IPInputField.text = "192.168.45.115:8080"
	}
}
