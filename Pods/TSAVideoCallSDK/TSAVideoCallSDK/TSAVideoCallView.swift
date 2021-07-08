//
//  TSAVideoCallView.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 08.07.2021.
//

import Foundation
import UIKit
import WebRTC

public class TSAVideoCallView: UIView{
    
    var videoSize: CGSize = CGSize()
    var lowLevel: [UIImage]? = nil
    var mediumLevel: [UIImage]? = nil
    var loudLevel: [UIImage]? = nil
    
    lazy var micButton: UIImageView = {
        let micButton = UIImageView()
        return micButton
    }()
    
    lazy var textMessage: UILabel = {
        let textMessage = UILabel()
        return textMessage
    }()
    
    lazy var videoView: RTCEAGLVideoView = {
        let videoView = RTCEAGLVideoView(frame: .zero)
        videoView.transform = CGAffineTransform.init(scaleX: -1.0, y: 1.0)
        videoView.contentMode = UIView.ContentMode.scaleAspectFill
        return videoView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        videoSize.width = frame.width
        videoSize.height = frame.height
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public func setVideoSize(size: CGSize){
        videoSize = size
    }
    
    public func getVideoSize() -> CGSize{
        return videoSize
    }
    
    private func setupView(){
       addSubview(videoView)
       addSubview(micButton)
    }
    
    public func getVideoView() -> RTCEAGLVideoView {
        return videoView
    }
 
    public func getMicView() -> UIImageView {
        return micButton
    }
    
    public func setAudioLevel(level: NSNumber){
        let level = Int(truncating: level)
        if (level > 0 && level < 30){
            if let loudLevel = loudLevel {
                micButton.animationImages = loudLevel
            }
        }else if(level >= 30 && level < 60){
            if let mediumLevel = mediumLevel {
                micButton.animationImages = mediumLevel
            }
        }else{
            if let lowLevel = lowLevel {
                micButton.animationImages = lowLevel
            }
        }
        
        if micButton.animationImages != nil {
            micButton.animationDuration = 1
            micButton.startAnimating()
        }
        
    }
    
    public func stopAnimation(){
        micButton.stopAnimating()
    }
    
    public func animationSet(lowLevel: [UIImage], mediumLevel: [UIImage], loudLevel: [UIImage]){
        self.lowLevel = lowLevel
        self.mediumLevel = mediumLevel
        self.loudLevel = loudLevel
    }
}
