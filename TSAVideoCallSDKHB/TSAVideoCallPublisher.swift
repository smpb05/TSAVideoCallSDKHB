//
//  TSAVideoCallPublisher.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import WebRTC

public class TSAVideoCallPublisher {
 
    
    let renderer = TSAVideoCallView()
    public weak var delegate: TSAVideoCallPublisherDelegate?
    
    public init(session: TSAVideoCallSession) {
        
    }
    
    public func getVideoView() -> TSAVideoCallView{
        return renderer
    }
    
    public func getAGLRenderer() -> RTCEAGLVideoView{
        return renderer.getVideoView()
    }
}
