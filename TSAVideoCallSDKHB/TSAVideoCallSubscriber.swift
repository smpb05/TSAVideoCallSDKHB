//
//  TSAVideoCallSubscriber.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import WebRTC
import UIKit

public class TSAVideoCallSubscriber {
    
    let renderer: TSAVideoCallView = TSAVideoCallView()
    public weak var delegate: TSAVideoCallSubscriberDelegate?
    private var stream: TSAVideoCallStream
    private var videoSize: CGSize? = nil
    
    public init(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        self.stream = stream
    }
    
    public func getVideoView() -> RTCEAGLVideoView{
        return renderer.getVideoView()
    }
    
    public func getStream() -> RTCMediaStream{
        return stream.getStream()
    }
    
    public func getHandleId() -> AnyHashable?{
        return stream.getHandleId()
    }
    
    public func setVideoSize(size: CGSize){
        self.videoSize = size
    }
    
    public func getVideoSize() -> CGSize?{
        return videoSize
    }

}
