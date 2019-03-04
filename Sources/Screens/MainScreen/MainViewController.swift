//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
	
	private let signalClient: SignalingClient
	private let webRTCClient: WebRTCClient
	
	@IBOutlet private weak var signalingStatusLabel: UILabel?
	@IBOutlet private weak var localSdpStatusLabel: UILabel?
	@IBOutlet private weak var localCandidatesLabel: UILabel?
	@IBOutlet private weak var remoteSdpStatusLabel: UILabel?
	@IBOutlet private weak var remoteCandidatesLabel: UILabel?
	@IBOutlet private weak var webRTCStatusLabel: UILabel?
	
	@IBOutlet private weak var speakerButton: UIButton?
	
	private var signalingConnected: Bool = false {
		didSet {
			DispatchQueue.main.async {
				self.signalingStatusLabel?.text = self.signalingConnected ? "Connected" : "Not connected"
				self.signalingStatusLabel?.textColor = self.signalingConnected ? .green : .red
			}
		}
	}
	
	private var hasLocalSdp: Bool = false {
		didSet {
			DispatchQueue.main.async {
				self.localSdpStatusLabel?.text = self.hasLocalSdp ? "✅" : "❌"
			}
		}
	}
	
	private var localCandidateCount: Int = 0 {
		didSet {
			DispatchQueue.main.async {
				self.localCandidatesLabel?.text = "\(self.localCandidateCount)"
			}
		}
	}
	
	private var hasRemoteSdp: Bool = false {
		didSet {
			DispatchQueue.main.async {
				self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
			}
		}
	}
	
	private var remoteCandidateCount: Int = 0 {
		didSet {
			DispatchQueue.main.async {
				self.remoteCandidatesLabel?.text = "\(self.remoteCandidateCount)"
			}
		}
	}
	
	init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
		self.signalClient = signalClient
		self.webRTCClient = webRTCClient
		super.init(nibName: String(describing: MainViewController.self), bundle: Bundle.main)
	}
	
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "WebRTC Demo"
		signalingConnected = false
		hasLocalSdp = false
		hasRemoteSdp = false
		localCandidateCount = 0
		remoteCandidateCount = 0
		webRTCStatusLabel?.text = "New"
		
		signalClient.connect()
		webRTCClient.delegate = self
		signalClient.delegate = self
	}
	
	@IBAction private func offerDidTap(_ sender: UIButton) {
		webRTCClient.offer { sdp in
			self.hasLocalSdp = true
			self.signalClient.send(sdp: sdp)
		}
	}
	
	@IBAction private func answerDidTap(_ sender: UIButton) {
		webRTCClient.answer { localSdp in
			self.hasLocalSdp = true
			self.signalClient.send(sdp: localSdp)
		}
	}
	
	@IBAction private func videoDidTap(_ sender: UIButton) {
		let vc = VideoViewController(webRTCClient: webRTCClient)
		present(vc, animated: true)
	}
	
	@IBAction func sendDataDidTap(_ sender: UIButton) {
		let alert = UIAlertController(title: "Send a message to the other peer",
																	message: "This will be transferred over WebRTC data channel",
																	preferredStyle: .alert)
		alert.addTextField { textField in
			textField.placeholder = "Message to send"
		}
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
			guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
				return
			}
			self?.webRTCClient.sendData(dataToSend)
		}))
		present(alert, animated: true)
	}
}

extension MainViewController: SignalClientDelegate {
	
	func signalClientDidConnect(_ signalClient: SignalingClient) {
		signalingConnected = true
	}
	
	func signalClientDidDisconnect(_ signalClient: SignalingClient) {
		signalingConnected = false
	}
	
	func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
		print("Received remote sdp")
		webRTCClient.set(remoteSdp: sdp) { error in
			self.hasRemoteSdp = true
		}
	}
	
	func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
		print("Received remote candidate")
		remoteCandidateCount += 1
		webRTCClient.set(remoteCandidate: candidate)
	}
}

extension MainViewController: WebRTCClientDelegate {
	
	func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
		print("discovered local candidate")
		localCandidateCount += 1
		signalClient.send(candidate: candidate)
	}
	
	func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
		let textColor: UIColor
		switch state {
		case .connected, .completed:
			textColor = .green
		case .disconnected:
			textColor = .orange
		case .failed, .closed:
			textColor = .red
		case .new, .checking, .count:
			textColor = .black
		}
		DispatchQueue.main.async {
			self.webRTCStatusLabel?.text = state.description.capitalized
			self.webRTCStatusLabel?.textColor = textColor
		}
	}
	
	func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
		DispatchQueue.main.async {
			let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
			let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel))
			self.present(alert, animated: true)
		}
	}
}

