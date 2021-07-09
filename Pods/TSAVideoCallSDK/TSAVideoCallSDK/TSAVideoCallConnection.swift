//
//  TSAVideoCallConnection.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
import WebRTC

public class TSAVideoCallConnection: NSObject {
    public var handleId: NSNumber?
    public var connection: RTCPeerConnection?
    public var videoTrack: RTCVideoTrack?
    public var videoView: RTCEAGLVideoView?
}
