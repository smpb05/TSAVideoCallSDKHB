//
//  TSAVideoCallPublisher.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import WebRTC

public class TSAVideoCallPublisher {
    
    let renderer = RTCCameraPreviewView(frame: .zero)
    public weak var delegate: TSAVideoCallPublisherDelegate?
    private var session: TSAVideoCallSession
    private var audio = true
    private var video = true
    
    public init(session: TSAVideoCallSession) {
        self.session = session
    }
    
    public func getVideoView() -> RTCCameraPreviewView{
        return renderer
    }
    
    public func publishAudio(audio: Bool){
        self.audio = audio
        session.onMediaTap(audio: audio, video: self.video )
    }
    
    public func publishVideo(video: Bool){
        self.video = video
        session.onMediaTap(audio: self.audio, video: video)
    }

    
    public func switchCamera(){
        session.switchCamera()
    }
    
    public func hangup(){
        
    }
    
    
}
