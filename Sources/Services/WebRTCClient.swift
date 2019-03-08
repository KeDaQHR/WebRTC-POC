//
//  WebRTCClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation

protocol WebRTCClientDelegate: class {
	func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
	func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
	func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
}

final class WebRTCClient: NSObject {
	
	// The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
	// A new RTCPeerConnection should be created every new call, but the factory is shared.
	private static let factory: RTCPeerConnectionFactory = {
		RTCInitializeSSL()
		let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
		let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
		return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory,
																		decoderFactory: videoDecoderFactory)
	}()
	
	weak var delegate: WebRTCClientDelegate?
	private let peerConnection: RTCPeerConnection
	
	private let rtcAudioSession = RTCAudioSession.sharedInstance()
	private let audioQueue = DispatchQueue(label: "audio")
	private var localAudioTrack: RTCAudioTrack?
	
	private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
																 kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
	
	private var videoCapturer: RTCVideoCapturer?
	private var localVideoRenderer: RTCVideoRenderer?
	private var localVideoTrack: RTCVideoTrack?
	private var remoteVideoRenderer: RTCVideoRenderer?
	private var remoteVideoTrack: RTCVideoTrack?
	
	private var localDataChannel: RTCDataChannel?
	private var remoteDataChannel: RTCDataChannel?
	
	@available(*, unavailable)
	override init() {
		fatalError("WebRTCClient:init is unavailable")
	}
	
	required init(iceServers: [String]) {
		let config = RTCConfiguration()
		config.iceServers = [RTCIceServer(urlStrings: iceServers)]
		
		// Unified plan is more superior than planB
		config.sdpSemantics = .unifiedPlan
		
		// gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
		config.continualGatheringPolicy = .gatherContinually
		
		let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
																					optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
		self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
		
		super.init()
		self.createMediaSenders()
		self.configureAudioSession()
		self.peerConnection.delegate = self
	}
	
	// MARK: - Signaling
	func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
		let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
																				 optionalConstraints: nil)
		peerConnection.offer(for: constrains) { [weak self] sdp, error in
			guard let sdp = sdp else { return }
			self?.peerConnection.setLocalDescription(sdp, completionHandler: { error in
				completion(sdp)
			})
		}
	}
	
	func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
		let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
																				 optionalConstraints: nil)
		peerConnection.answer(for: constrains) { [weak self] sdp, error in
			guard let sdp = sdp else { return }
			self?.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
				completion(sdp)
			})
		}
	}
	
	func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
		peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
	}
	
	func set(remoteCandidate: RTCIceCandidate) {
		peerConnection.add(remoteCandidate)
	}
	
	// MARK: Media
	func startCaptureLocalVideo(renderer: RTCVideoRenderer, cameraPoistion: AVCaptureDevice.Position = .front) {
		guard let capturer = videoCapturer as? RTCCameraVideoCapturer else { return }
		
		guard let camera = (RTCCameraVideoCapturer.captureDevices().first { $0.position ==  cameraPoistion }),
			
			// choose highest res
			let format = (RTCCameraVideoCapturer.supportedFormats(for: camera).sorted { (f1, f2) -> Bool in
				let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
				let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
				return width1 < width2
			}).last,
			
			// choose highest fps
			let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
				return
		}
		
		capturer.startCapture(with: camera,
													format: format,
													fps: Int(fps.maxFrameRate))
		
		localVideoTrack?.add(renderer)
		localVideoRenderer = renderer
	}
	
	func stopCaptureLocalVideo(renderer: RTCVideoRenderer) {
		localVideoTrack?.remove(renderer)
		localVideoRenderer = nil
	}
	
	func renderRemoteVideo(to renderer: RTCVideoRenderer) {
		remoteVideoTrack?.add(renderer)
		remoteVideoRenderer = renderer
	}
	
	func stopRenderRemoteVideo(to renderer: RTCVideoRenderer) {
		remoteVideoTrack?.remove(renderer)
		remoteVideoRenderer = nil
	}
	
	private func configureAudioSession() {
		rtcAudioSession.lockForConfiguration()
		do {
			try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
			try rtcAudioSession.setMode(AVAudioSession.Mode.videoChat.rawValue)
		} catch let error {
			debugPrint("Error changeing AVAudioSession category: \(error)")
		}
		rtcAudioSession.unlockForConfiguration()
	}
	
	private func createMediaSenders() {
		let streamId = "stream"
		
		// Audio
		let audioTrack = createAudioTrack()
		localAudioTrack = audioTrack
		peerConnection.add(audioTrack, streamIds: [streamId])
		
		// Video
		let videoTrack = createVideoTrack()
		localVideoTrack = videoTrack
		peerConnection.add(videoTrack, streamIds: [streamId])
		remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
		
		// Data
		if let dataChannel = createDataChannel() {
			dataChannel.delegate = self
			localDataChannel = dataChannel
		}
	}
	
	private func createAudioTrack() -> RTCAudioTrack {
		let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
		let audioSource = WebRTCClient.factory.audioSource(with: audioConstrains)
		let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
		return audioTrack
	}
	
	private func createVideoTrack() -> RTCVideoTrack {
		let videoSource = WebRTCClient.factory.videoSource()
		#if TARGET_OS_SIMULATOR
		videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
		#else
		videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
		#endif
		let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
		return videoTrack
	}
}

// MARK:- Audio control
extension WebRTCClient {
	
	func muteAudio() {
		localAudioTrack?.isEnabled = false
	}
	
	func unmuteAudio() {
		localAudioTrack?.isEnabled = true
	}
	
	// Fallback to the default playing device: headphones/bluetooth/ear speaker
	func speakerOff() {
		audioQueue.async { [weak self] in
			self?.rtcAudioSession.lockForConfiguration()
			do {
				try self?.rtcAudioSession.overrideOutputAudioPort(.none)
			} catch let error {
				debugPrint("Error setting AVAudioSession category: \(error)")
			}
			self?.rtcAudioSession.unlockForConfiguration()
		}
	}
	
	// Force speaker
	func speakerOn() {
		audioQueue.async { [weak self] in
			self?.rtcAudioSession.lockForConfiguration()
			do {
				try self?.rtcAudioSession.overrideOutputAudioPort(.speaker)
			} catch let error {
				debugPrint("Couldn't force audio to speaker: \(error)")
			}
			self?.rtcAudioSession.unlockForConfiguration()
		}
	}
}

// MARK:- Video control
extension WebRTCClient {
	
	func disableVideo() {
		localVideoTrack?.isEnabled = false
	}
	
	func enableVideo() {
		localVideoTrack?.isEnabled = true
	}
	
	func useFrontCamera() {
		guard let renderer = localVideoRenderer else { return }
		stopCaptureLocalVideo(renderer: renderer)
		startCaptureLocalVideo(renderer: renderer, cameraPoistion: .front)
	}
	
	func useBackCamera() {
		guard let renderer = localVideoRenderer else { return }
		stopCaptureLocalVideo(renderer: renderer)
		startCaptureLocalVideo(renderer: renderer, cameraPoistion: .back)
	}
}

// MARK: - RTCPeerConnectionDelegate
extension WebRTCClient: RTCPeerConnectionDelegate {
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
		debugPrint("peerConnection new signaling state: \(stateChanged)")
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		debugPrint("peerConnection did add stream")
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		debugPrint("peerConnection did remote stream")
	}
	
	func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
		debugPrint("peerConnection should negotiate")
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		debugPrint("peerConnection new connection state: \(newState)")
		self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
		debugPrint("peerConnection new gathering state: \(newState)")
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
		delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
		debugPrint("peerConnection did remove candidate(s)")
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
		debugPrint("peerConnection did open data channel")
		remoteDataChannel = dataChannel
	}
	
	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
		debugPrint("peerConnection did remove receiver \(rtpReceiver.track.debugDescription)")
	}
}

// MARK: - RTCDataChannel Functions and Delegates
extension WebRTCClient: RTCDataChannelDelegate {
	
	// Functions
	private func createDataChannel() -> RTCDataChannel? {
		let config = RTCDataChannelConfiguration()
		guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
			debugPrint("Warning: Couldn't create data channel.")
			return nil
		}
		return dataChannel
	}
	
	func sendData(_ data: Data) {
		let buffer = RTCDataBuffer(data: data, isBinary: true)
		remoteDataChannel?.sendData(buffer)
	}
	
	// Delegates
	func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		debugPrint("dataChannel did change state: \(dataChannel.readyState)")
	}
	
	func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		delegate?.webRTCClient(self, didReceiveData: buffer.data)
	}
}
