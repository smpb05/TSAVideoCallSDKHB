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
        changeFrame()
    }
    
    public func getVideoSize() -> CGSize?{
        return videoSize
    }
    
    private func changeFrame(){
        if let size = videoSize{
            
            let bounds = renderer.getVideoView().frame
           
            var scale = CGFloat(1)
            var x = bounds.minX
            var y = bounds.minY
            var newSize = size
            scale = bounds.height/size.height
            newSize = CGSize(width: size.width*scale, height: size.height*scale)
            if(size.width > size.height){
                x = (bounds.width-newSize.width)/2
                y = (bounds.height-newSize.height)/2
            }
            let rect = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            renderer.getVideoView().frame = rect
        }
        
    }
    
}
