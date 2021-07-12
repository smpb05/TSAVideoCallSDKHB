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
    private var session: TSAVideoCallSession
    
    public init(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        self.stream = stream
        self.session = session
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
    
    public func setFrame(bounds: CGRect){
        if let size = videoSize {
            if size.width > 0 && size.height > 0 {
                var remoteVideoFrame = AVMakeRect(aspectRatio: size, insideRect: bounds)
                var scale: CGFloat = 1
                if remoteVideoFrame.size.width > remoteVideoFrame.size.height {
                    scale = bounds.size.height / remoteVideoFrame.size.height
                }else{
                    scale = bounds.size.width / remoteVideoFrame.size.width
                }
                remoteVideoFrame.size.height *= scale
                remoteVideoFrame.size.width *= scale
                renderer.getVideoView().frame = remoteVideoFrame
                renderer.getVideoView().center = CGPoint(x: bounds.midX, y: bounds.midY)
            }else {
                renderer.getVideoView().frame = bounds
            }
        }
    }

}
