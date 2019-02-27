//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import Starscream

protocol SignalClientDelegate: class {
	func signalClientDidConnect(_ signalClient: SignalingClient)
	func signalClientDidDisconnect(_ signalClient: SignalingClient)
	func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
	func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
	
	private let socket: WebSocket
	private let decoder = JSONDecoder()
	private let encoder = JSONEncoder()
	weak var delegate: SignalClientDelegate?
	
	init(serverUrl: URL) {
		socket = WebSocket(url: serverUrl)
	}
	
	func connect() {
		socket.delegate = self
		socket.connect()
	}
	
	func send(sdp rtcSdp: RTCSessionDescription) {
		let message = Message.sdp(SessionDescription(from: rtcSdp))
		do {
			let dataMessage = try encoder.encode(message)
			socket.write(data: dataMessage)
		} catch {
			debugPrint("Warning: Could not encode sdp: \(error)")
		}
	}
	
	func send(candidate rtcIceCandidate: RTCIceCandidate) {
		let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
		do {
			let dataMessage = try encoder.encode(message)
			socket.write(data: dataMessage)
		} catch {
			debugPrint("Warning: Could not encode candidate: \(error)")
		}
	}
}

extension SignalingClient: WebSocketDelegate {
	
	func websocketDidConnect(socket: WebSocketClient) {
		delegate?.signalClientDidConnect(self)
	}
	
	func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
		delegate?.signalClientDidDisconnect(self)
		
		// try to reconnect every two seconds
		DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
			debugPrint("Trying to reconnect to signaling server...")
			self.socket.connect()
		}
	}
	
	func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
		let message: Message
		do {
			message = try decoder.decode(Message.self, from: data)
		} catch {
			debugPrint("Warning: Could not decode incoming message: \(error)")
			return
		}
		
		switch message {
		case .candidate(let iceCandidate):
			delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
		case .sdp(let sessionDescription):
			delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
		}
	}
	
	func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {}
}
