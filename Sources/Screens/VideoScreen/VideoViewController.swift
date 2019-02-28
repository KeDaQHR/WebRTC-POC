//
//  VideoViewController.swift
//  WebRTC
//
//  Created by Stasel on 21/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {
	
	@IBOutlet private weak var localVideoView: UIView?
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var videoControlButton: UIButton!
	@IBOutlet private var endCallButton: UIButton!
	@IBOutlet private var audioControlButton: UIButton!
	
	@IBAction private func videoStatusToggled(_ sender: Any) {
		
	}
	
	@IBAction private func endCallButtonTapped(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func audioStatusToggled(_ sender: Any) {
		
	}
	
	private let webRTCClient: WebRTCClient
	
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
		let localRenderer = RTCMTLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
		let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
		localRenderer.videoContentMode = .scaleAspectFill
		remoteRenderer.videoContentMode = .scaleAspectFill
		#else
		// Using OpenGLES for the rest
		let localRenderer = RTCEAGLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
		let remoteRenderer = RTCEAGLVideoView(frame: self.view.frame)
		#endif
		
		self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
		self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
		
		if let localVideoView = self.localVideoView {
			self.embedView(localRenderer, into: localVideoView)
		}
		self.embedView(remoteRenderer, into: self.view)
		self.view.sendSubviewToBack(remoteRenderer)
	}
	
	private func embedView(_ view: UIView, into containerView: UIView) {
		containerView.addSubview(view)
		view.translatesAutoresizingMaskIntoConstraints = false
		containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
																																options: [],
																																metrics: nil,
																																views: ["view":view]))
		
		containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
																																options: [],
																																metrics: nil,
																																views: ["view":view]))
		containerView.layoutIfNeeded()
	}
}
