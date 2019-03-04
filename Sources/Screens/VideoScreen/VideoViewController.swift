//
//  VideoViewController.swift
//  WebRTC
//
//  Created by Stasel on 21/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {
	
	// MARK: - Outlets
	
	@IBOutlet private var localVideoView: UIView!
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var flipCameraButton: UIButton!
	@IBOutlet private var videoControlButton: UIButton!
	@IBOutlet private var endCallButton: UIButton!
	@IBOutlet private var audioControlButton: UIButton!
	
	@IBAction func cameraToggled(_ sender: Any) {
		
	}
	
	@IBAction private func videoStatusToggled(_ sender: Any) {
		
	}
	
	@IBAction private func endCallButtonTapped(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func audioStatusToggled(_ sender: Any) {
		mute.toggle()
		if mute {
			webRTCClient.muteAudio()
		} else {
			webRTCClient.unmuteAudio()
		}
	}
	
	// MARK: - Properties
	
	private let webRTCClient: WebRTCClient
	
	private var mute: Bool = false {
		didSet {
			let statusImage = mute ? #imageLiteral(resourceName: "AudioIconOff") : #imageLiteral(resourceName: "AudioIconOn")
			audioControlButton?.setImage(statusImage, for: .normal)
		}
	}
	
	init(webRTCClient: WebRTCClient) {
		self.webRTCClient = webRTCClient
		super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)
	}
	
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		#if arch(arm64)
		// Using metal (arm64 only)
		let localRenderer = RTCMTLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
		let remoteRenderer = RTCMTLVideoView(frame: view.frame)
		localRenderer.videoContentMode = .scaleAspectFill
		remoteRenderer.videoContentMode = .scaleAspectFill

		#else
		// Using OpenGLES for the rest
		let localRenderer = RTCEAGLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
		let remoteRenderer = RTCEAGLVideoView(frame: view.frame)
		#endif
		
		webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
		webRTCClient.renderRemoteVideo(to: remoteRenderer)
		
		embedView(localRenderer, into: localVideoView)
		embedView(remoteRenderer, into: view)
		view.sendSubviewToBack(remoteRenderer)
	}
	
	private func embedView(_ view: UIView, into containerView: UIView) {
		containerView.addSubview(view)
		view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: containerView.topAnchor),
			view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
			view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		])
		containerView.layoutIfNeeded()
	}
}
