//
//  TSAVideoCallStream.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import Foundation
import WebRTC
public class TSAVideoCallStream {
    
    private var handleId: AnyHashable?
    private var stream: RTCMediaStream
    
    public init(handleId: AnyHashable?, stream: RTCMediaStream){
        self.handleId = handleId
        self.stream = stream
    }
    
    public func getStream() -> RTCMediaStream{
        return stream
    }
    
    public func getHandleId() -> AnyHashable?{
        return handleId
    }
    
    
}
