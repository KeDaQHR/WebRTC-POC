//
//  AppDelegate.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	private var window: UIWindow?
	private let config = Config.default
	
	func application(_ application: UIApplication,
									 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let window = UIWindow(frame: UIScreen.main.bounds)
		
		let IPInputPage = IPInputController()
		IPInputPage.onContinuePerformed = { [weak self] ipAddress in
			guard let self = self else { return }
			let mainPage = self.buildMainViewController(with: ipAddress)
			window.rootViewController?.present(mainPage, animated: true)
		}
		
		window.rootViewController = IPInputPage
		window.makeKeyAndVisible()
		self.window = window
		return true
	}
	
	private func buildMainViewController(with IPAddress: String) -> UIViewController {
		let signalClient = SignalingClient(serverUrl: URL(string: "ws://\(IPAddress)/")!)
		let webRTCClient = WebRTCClient(iceServers: config.webRTCIceServers)
		let mainViewController = MainViewController(signalClient: signalClient,
																								webRTCClient: webRTCClient)
		let navViewController = UINavigationController(rootViewController: mainViewController)
		navViewController.navigationBar.isTranslucent = false
		if #available(iOS 11.0, *) {
			navViewController.navigationBar.prefersLargeTitles = true
		}
		return navViewController
	}
}

