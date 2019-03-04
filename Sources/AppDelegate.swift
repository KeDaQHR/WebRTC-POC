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
	
	// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
	fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
																			 "stun:stun1.l.google.com:19302",
																			 "stun:stun2.l.google.com:19302",
																			 "stun:stun3.l.google.com:19302",
																			 "stun:stun4.l.google.com:19302"]
	
	private var window: UIWindow?
	
	func application(_ application: UIApplication,
									 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let window = UIWindow(frame: UIScreen.main.bounds)
		
		let IPInputPage = IPInputController()
		IPInputPage.onContinuePerformed = { [weak self] ipAddress in
			guard let self = self else { return }
			guard let mainPage = self.buildMainViewController(with: ipAddress) else { return }
			window.rootViewController?.present(mainPage, animated: true)
		}
		
		window.rootViewController = IPInputPage
		window.makeKeyAndVisible()
		self.window = window
		return true
	}
	
	private func buildMainViewController(with IPAddress: String) -> UIViewController? {
		// Set this to the machine's address which runs the signaling server
		guard let defaultSignalingServerUrl = URL(string: "ws://\(IPAddress)/") else {
			return nil
		}
		
		let signalClient = SignalingClient(serverUrl: defaultSignalingServerUrl)
		let webRTCClient = WebRTCClient(iceServers: defaultIceServers)
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

