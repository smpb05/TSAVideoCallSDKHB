//
//  TSAVideoCallVideoView.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
import UIKit
import WebRTC

public class TSAVideoCallView: UIView{
    
    var videoSize: CGSize = CGSize()
    let lowLevel: [UIImage] = [UIImage(named: "mic_0")!, UIImage(named: "mic_1")!]
    let mediumLevel: [UIImage] = [UIImage(named: "mic_2")!, UIImage(named: "mic_3")!]
    let loudLevel: [UIImage] = [UIImage(named: "mic_4")!, UIImage(named: "mic_5")!]
    
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
            micButton.animationImages = loudLevel
        }else if(level >= 30 && level < 60){
            micButton.animationImages = mediumLevel
        }else{
            micButton.animationImages = lowLevel
        }
        micButton.animationDuration = 1
        micButton.startAnimating()
    }
    
    public func stopAnimation(){
        micButton.stopAnimating()
    }
    
}
