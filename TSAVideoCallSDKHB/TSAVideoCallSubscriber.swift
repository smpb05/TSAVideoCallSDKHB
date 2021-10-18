//
//  TSAVideoCallSubscriber.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import WebRTC
import UIKit

public class TSAVideoCallSubscriber: RTCEAGLVideoViewDelegate {
    
    public func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        self.videoSize = size
        let bounds = frame
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
    
    let renderer: TSAVideoCallView = TSAVideoCallView()
    public weak var delegate: TSAVideoCallSubscriberDelegate?
    private var stream: TSAVideoCallStream
    private var videoSize: CGSize? = nil
    private var session: TSAVideoCallSession
    private var frame: CGRect
    
    public init(session: TSAVideoCallSession, stream: TSAVideoCallStream, frame: CGRect) {
        self.stream = stream
        self.session = session
        self.frame = frame
        self.renderer.getVideoView().delegate = self
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
    
    public func getTSAVideoCallStream() -> TSAVideoCallStream?{
        return stream
    }

}
