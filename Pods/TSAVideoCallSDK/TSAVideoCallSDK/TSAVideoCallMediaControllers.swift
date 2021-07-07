//
//  TSAVideoCallMediaControllers.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
import UIKit
class TSAMediaControllersView: UIView {
    
    var mediaControllersViewDelegate: TSAVideoCallMediaControllersViewDelegate?
   
    var audio = true
    var video = true

   
   lazy var micButton: UIImageView = {
       let micButton = UIImageView(frame: CGRect(x: 8, y: 8, width: 32, height: 32))
       micButton.image = UIImage(named: "outline_mic_none_white_20pt")
       micButton.tintColor = .white
       return micButton
   }()
   
   lazy var micButtonBg: UIImageView = {
       let micButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
       micButton.layer.borderWidth = 1
       micButton.layer.borderColor = UIColor.white.cgColor
       micButton.layer.masksToBounds = false
       micButton.layer.cornerRadius = 24

       return micButton
   }()
   
   lazy var videoButton: UIImageView = {
       let videoButton = UIImageView(frame: CGRect(x: 68, y: 8, width: 32, height: 32))
       videoButton.image = UIImage(named: "outline_videocam_white_20pt")
       videoButton.tintColor = .white
       return videoButton
   }()
   
   lazy var videoButtonBg: UIImageView = {
       let videoButton = UIImageView(frame: CGRect(x: 60, y: 0, width: 48, height: 48))
       videoButton.layer.borderWidth = 1
       videoButton.layer.borderColor = UIColor.white.cgColor
       videoButton.layer.masksToBounds = false
       videoButton.layer.cornerRadius = 24
       return videoButton
   }()
   
   lazy var switchCameraButton: UIImageView = {
       let switchCameraButton = UIImageView(frame: CGRect(x: 128, y: 8, width: 32, height: 32))
       switchCameraButton.image = UIImage(named: "outline_flip_camera_ios_white_20pt")
       switchCameraButton.tintColor = .white
       return switchCameraButton
   }()
   
   lazy var switchCameraButtonBg: UIImageView = {
       let switchCameraButtonBg = UIImageView(frame: CGRect(x: 120, y: 0, width: 48, height: 48))

       switchCameraButtonBg.layer.borderWidth = 1
       switchCameraButtonBg.layer.borderColor = UIColor.white.cgColor
       switchCameraButtonBg.layer.masksToBounds = false
       switchCameraButtonBg.layer.cornerRadius = 24
       
       return switchCameraButtonBg
   }()
   
   
   lazy var hangupButton: UIImageView = {
       let hangupButton = UIImageView(frame: CGRect(x: 200, y: 8, width: 32, height: 32))
       hangupButton.image = UIImage(named: "outline_call_end_white_20pt")
       hangupButton.tintColor = .white
       return hangupButton
   }()
   
   
   lazy var hangupButtonBg: UIImageView = {
       let hangupButton = UIImageView(frame: CGRect(x: 192, y: 0, width: 48, height: 48))

       hangupButton.layer.borderWidth = 1
       hangupButton.layer.backgroundColor = UIColor.red.cgColor
       hangupButton.layer.borderColor = UIColor.red.cgColor
       hangupButton.layer.masksToBounds = false
       hangupButton.layer.cornerRadius = 24
       
       return hangupButton
   }()
   
   
   
   override init(frame: CGRect) {
       super.init(frame: frame)
       setupViews()
   }
   
   required init?(coder: NSCoder) {
       super.init(coder: coder)
       setupViews()
   }
   
   private func setupViews(){
    
       let micGestureAction = UITapGestureRecognizer(target: self, action: #selector(self.onMicTap(_:)))
       micButtonBg.addGestureRecognizer(micGestureAction)
       micButtonBg.isUserInteractionEnabled = true
       addSubview(micButton)
       addSubview(micButtonBg)
       
       let videoGestureAction = UITapGestureRecognizer(target: self, action: #selector(self.onVideoTap(_:)))
       videoButtonBg.addGestureRecognizer(videoGestureAction)
       videoButtonBg.isUserInteractionEnabled = true
       addSubview(videoButton)
       addSubview(videoButtonBg)
       
       let switchGestureAction = UITapGestureRecognizer(target: self, action: #selector(self.onSwitchTap(_:)))
       switchCameraButtonBg.addGestureRecognizer(switchGestureAction)
       switchCameraButtonBg.isUserInteractionEnabled = true
       addSubview(switchCameraButton)
       addSubview(switchCameraButtonBg)
       
       let hangupGestureAction = UITapGestureRecognizer(target: self, action: #selector(self.onHangupTap(_:)))
       hangupButtonBg.addGestureRecognizer(hangupGestureAction)
       hangupButtonBg.isUserInteractionEnabled = true
       addSubview(hangupButtonBg)
       addSubview(hangupButton)
       
   }
   
   @objc func onMicTap(_ sender: UITapGestureRecognizer){
       if audio {
           setMicOff()
           audio = false
       }else{
           setMicOn()
           audio = true
       }
       mediaControllersViewDelegate?.onMediaTap(sender: micButtonBg, audio: audio, video: video)
   }
   
   @objc func onVideoTap(_ sender: UITapGestureRecognizer){
       if video {
           setVideoOff()
           video = false
       }else{
           setVideoOn()
           video = true
       }
       mediaControllersViewDelegate?.onMediaTap(sender: videoButtonBg, audio: audio, video: video)
   }
   
   @objc func onSwitchTap(_ sender: UITapGestureRecognizer){
       mediaControllersViewDelegate?.onSwitchCamTap(sender: switchCameraButtonBg)
   }
   
   @objc func onHangupTap(_ sender: UITapGestureRecognizer){
       mediaControllersViewDelegate?.onHangupTap(sender: hangupButtonBg)
   }
   
   public func setMicOff(){
       micButton.image = UIImage(named: "outline_mic_off_white_20pt")
   }
   
   public func setMicOn(){
        micButton.image = UIImage(named: "outline_mic_none_white_20pt")
   }
   
   public func setVideoOff(){
        videoButton.image = UIImage(named: "outline_videocam_off_white_20pt")
   }
   
   public func setVideoOn(){
        videoButton.image = UIImage(named: "outline_videocam_white_20pt")
   }
}
