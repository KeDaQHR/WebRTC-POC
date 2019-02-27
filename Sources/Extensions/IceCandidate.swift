//
//  IceCandidate.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
struct IceCandidate: Codable {
	let sdp: String
	let sdpMLineIndex: Int32
	let sdpMid: String?
	
	init(from iceCandidate: RTCIceCandidate) {
		self.sdpMLineIndex = iceCandidate.sdpMLineIndex
		self.sdpMid = iceCandidate.sdpMid
		self.sdp = iceCandidate.sdp
	}
	
	var rtcIceCandidate: RTCIceCandidate {
		return RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
	}
}
