//
//  MapleRTCVideoView.swift
//  WebRTC-Demo
//
//  Created by Ke Ma on 2019-03-05.
//  Copyright © 2019 Stas Seldin. All rights reserved.
//

import UIKit

class RTCVideoView: UIView {
	
	// MARK: - Public Properties
	
	var isVideoBlocked: Bool = false {
		didSet {
			blurView.isHidden = !isVideoBlocked
			videoIconView.isHidden = !isVideoBlocked
		}
	}
	
	var isAudioBlocked: Bool = false {
		didSet {
			audioIconView.isHidden = !isAudioBlocked
		}
	}
	
	// MARK: - Life Cycle
	
	override init(frame: CGRect) {
		#if arch(arm64)
		self.renderer = RTCMTLVideoView(frame: frame)
		self.renderer.videoContentMode = .scaleAspectFill
		#else
		self.renderer = RTCEAGLVideoView(frame: frame)
		#endif
		
		super.init(frame: frame)
		
		// Renderer may go out of bounds if not set to true
		clipsToBounds = true
		
		addSubview(renderer)
		addSubview(blurView)
		addSubview(videoIconView)
		addSubview(audioIconView)
		
		renderer.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			renderer.topAnchor.constraint(equalTo: topAnchor),
			renderer.leftAnchor.constraint(equalTo: leftAnchor),
			renderer.rightAnchor.constraint(equalTo: rightAnchor),
			renderer.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
		
		blurView.isHidden = true
		blurView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			blurView.topAnchor.constraint(equalTo: topAnchor),
			blurView.leftAnchor.constraint(equalTo: leftAnchor),
			blurView.rightAnchor.constraint(equalTo: rightAnchor),
			blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
		
		videoIconView.image = #imageLiteral(resourceName: "MiniVideoIcon")
		videoIconView.isHidden = true
		videoIconView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			videoIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
			videoIconView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		audioIconView.image = #imageLiteral(resourceName: "MiniAudioIcon")
		audioIconView.isHidden = true
		audioIconView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			audioIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
			audioIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0)
		])
	}
	
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - UI Elements
	
	#if arch(arm64)
	// Using metal (arm64 only)
	var renderer: RTCMTLVideoView
	#else
	// Using OpenGLES for the rest
	var renderer: RTCEAGLVideoView
	#endif
	
	private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
	private let videoIconView = UIImageView()
	private let audioIconView = UIImageView()
}
