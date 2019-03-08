//
//  VideoViewController.swift
//  WebRTC
//
//  Created by Stasel on 21/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

class VideoViewController: UIViewController {
	
	// MARK: - Outlet Functions
	
	@IBAction func minimizeButtonTapped(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func speakerStatusToggled(_ sender: Any) {
		isSpeakerOn.toggle()
		if isSpeakerOn {
			webRTCClient.speakerOn()
		} else {
			webRTCClient.speakerOff()
		}
	}
	
	@IBAction func cameraPositionToggled(_ sender: Any) {
		isFrontCamera.toggle()
		if isFrontCamera {
			webRTCClient.useFrontCamera()
		} else {
			webRTCClient.useBackCamera()
		}
	}
	
	@IBAction private func videoStatusToggled(_ sender: Any) {
		isVideoBlocked.toggle()
		if isVideoBlocked {
			webRTCClient.disableVideo()
		} else {
			webRTCClient.enableVideo()
		}
	}
	
	@IBAction private func endCallButtonTapped(_ sender: Any) {
		//TODO: End call
	}
	
	@IBAction func audioStatusToggled(_ sender: Any) {
		isAudioBlocked.toggle()
		if isAudioBlocked {
			webRTCClient.muteAudio()
		} else {
			webRTCClient.unmuteAudio()
		}
	}
	
	// MARK: - Open Properties
	
	// Set this to update connection status
	var statusDescription: String? {
		didSet {
			statusLabel.text = statusDescription
		}
	}
	
	// Set this to update remoteView video block/unblock status
	var isRemoteVideoBlocked: Bool = false {
		didSet {
			remoteVideoView?.isVideoBlocked = isRemoteVideoBlocked
		}
	}
	
	// Set this to update remoteView audio block/unblock status
	var isRemoteAudioBlocked: Bool = false {
		didSet {
			remoteVideoView?.isAudioBlocked = isRemoteAudioBlocked
		}
	}
	
	// Set this to update remoteView blurView show/hide status
	// remoteView blurView will show for reconnection and maybe other cases
	var isRemoteBlurViewHidden: Bool = true {
		didSet {
			remoteVideoView?.isBlurViewHidden = isRemoteBlurViewHidden
		}
	}
	
	// MARK: - Private Properties
	
	private let webRTCClient: WebRTCClient
	
	private var isSpeakerOn: Bool = true {
		didSet {
			let title = "Speaker: \(isSpeakerOn ? "On" : "Off")"
			speakerStatusButton?.setTitle(title, for: .normal)
		}
	}
	
	private var isFrontCamera: Bool = true {
		didSet {
			let title = "Camera: \(isFrontCamera ? "Front" : "Back")"
			cameraPositionButton.setTitle(title, for: .normal)
		}
	}
	
	private var isAudioBlocked: Bool = false {
		didSet {
			let statusImage = isAudioBlocked ? #imageLiteral(resourceName: "AudioIconOff") : #imageLiteral(resourceName: "AudioIconOn")
			audioStatusButton?.setImage(statusImage, for: .normal)
			localVideoView?.isAudioBlocked = isAudioBlocked
		}
	}
	
	private var isVideoBlocked: Bool = false {
		didSet {
			let statusImage = isVideoBlocked ? #imageLiteral(resourceName: "VideoIconOff") : #imageLiteral(resourceName: "VideoIconOn")
			videoStatusButton?.setImage(statusImage, for: .normal)
			localVideoView?.isVideoBlocked = isVideoBlocked
		}
	}
	
	// MARK: - Life Cycle
	
	init(webRTCClient: WebRTCClient) {
		self.webRTCClient = webRTCClient
		super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)
	}
	
	deinit {
		debugPrint("--- VideoViewController is gone")
	}
	
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		localVideoView = RTCVideoView(frame: localVideoViewContainer?.frame ?? CGRect.zero)
		remoteVideoView = RTCVideoView(frame: view.frame)
		
		webRTCClient.startCaptureLocalVideo(renderer: localVideoView!.renderer)
		webRTCClient.renderRemoteVideo(to: remoteVideoView!.renderer)
		
		embedView(localVideoView!, into: localVideoViewContainer)
		embedView(remoteVideoView!, into: remoteVideoViewContainer)
		view.sendSubviewToBack(remoteVideoViewContainer)
		
		// Set up the initial status
		isSpeakerOn = true
		isFrontCamera = true
		isAudioBlocked = false
		isVideoBlocked = false
		
		// Turn on speaker by default
		webRTCClient.speakerOn()
		
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
	
	// MARK: - Private UI
	
	@IBOutlet private var localVideoViewContainer: UIView!
	@IBOutlet private var remoteVideoViewContainer: UIView!
	
	private var localVideoView: RTCVideoView?
	private var remoteVideoView: RTCVideoView?
	
	// Show the current call status like "connecting...", "poor connection", etc
	@IBOutlet private var statusLabel: UILabel!
	// Toggle speaker on/off
	@IBOutlet private var speakerStatusButton: UIButton!
	// Toggle camera position to front/back
	@IBOutlet private var cameraPositionButton: UIButton!
	// Toggle to let your peer see you or not
	@IBOutlet private var videoStatusButton: UIButton!
	// Toggle to let your peer hear you or not
	@IBOutlet private var audioStatusButton: UIButton!
	// End the call
	@IBOutlet private var endCallButton: UIButton!
}
