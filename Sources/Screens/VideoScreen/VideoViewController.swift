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
	
	@IBOutlet private var localVideoViewContainer: UIView!
	@IBOutlet private var remoteVideoViewContainer: UIView!
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var speakerToggleButton: UIButton!
	@IBOutlet private var flipCameraButton: UIButton!
	@IBOutlet private var videoControlButton: UIButton!
	@IBOutlet private var endCallButton: UIButton!
	@IBOutlet private var audioControlButton: UIButton!
	
	@IBAction func speakerToggled(_ sender: Any) {
		speakerOn.toggle()
		if speakerOn {
			webRTCClient.speakerOn()
		} else {
			webRTCClient.speakerOff()
		}
	}
	
	@IBAction func cameraToggled(_ sender: Any) {
		isFrontCamera.toggle()
		if isFrontCamera {
			webRTCClient.useFrontCamera()
		} else {
			webRTCClient.useBackCamera()
		}
	}
	
	@IBAction private func videoStatusToggled(_ sender: Any) {
		isSendingVideo.toggle()
		if isSendingVideo {
			webRTCClient.enableVideo()
		} else {
			webRTCClient.disableVideo()
		}
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
	
	private var speakerOn: Bool = true {
		didSet {
			let title = "Speaker: \(speakerOn ? "On" : "Off" )"
			speakerToggleButton?.setTitle(title, for: .normal)
		}
	}
	
	private var isSendingVideo: Bool = true {
		didSet {
			let statusImage = isSendingVideo ? #imageLiteral(resourceName: "VideoIconOn") : #imageLiteral(resourceName: "VideoIconOff")
			videoControlButton?.setImage(statusImage, for: .normal)
			(localVideoViewContainer.subviews.first as! RTCVideoView).isVideoBlocked = !isSendingVideo
		}
	}
	
	private var isFrontCamera: Bool = true {
		didSet {
			let title = "Camera: \(isFrontCamera ? "Front" : "Back" )"
			flipCameraButton.setTitle(title, for: .normal)
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
		let localVideoView = RTCVideoView(frame: localVideoViewContainer?.frame ?? CGRect.zero)
		let remoteVideoView = RTCVideoView(frame: view.frame)
		webRTCClient.startCaptureLocalVideo(renderer: localVideoView.renderer)
		webRTCClient.renderRemoteVideo(to: remoteVideoView.renderer)
		
		embedView(localVideoView, into: localVideoViewContainer)
		embedView(remoteVideoView, into: remoteVideoViewContainer)
		view.sendSubviewToBack(remoteVideoView)
		
		// Beautify localVideoView border
		localVideoViewContainer.clipsToBounds = true
		localVideoViewContainer.layer.borderWidth = 2.0
		localVideoViewContainer.layer.borderColor = UIColor.white.cgColor
		localVideoViewContainer.layer.cornerRadius = 5.0
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
