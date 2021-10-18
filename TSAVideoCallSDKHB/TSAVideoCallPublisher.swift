//
//  TSAVideoCallPublisher.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import WebRTC
import UIKit

public class TSAVideoCallPublisher{
    
    private var videoSize: CGSize? = nil
    
    let renderer = RTCCameraPreviewView(frame: .zero)
    public weak var delegate: TSAVideoCallPublisherDelegate?
    private var session: TSAVideoCallSession
    private var audio = true
    private var video = true
    private var prevSize: CGRect? = nil
    private var fullSize: CGRect = AVMakeRect(aspectRatio: CGSize(width: 2, height: 3), insideRect: UIScreen.main.bounds)
    private var view: RTCEAGLVideoView = RTCEAGLVideoView(frame: .zero)
    

    public init(session: TSAVideoCallSession) {
        self.session = session
        self.view.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    internal func setView(_ localView: RTCEAGLVideoView){
        self.view = localView
    }
    
    public func getVideoView() -> RTCEAGLVideoView{
        return view
    }

    internal func getCameraPreview()->RTCCameraPreviewView{
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
        session.switchCameraPreview()
    }
    
    public func hangup(){
        session.hangup()
    }
    
    internal func makeFullScreen(){
        prevSize = view.frame
        view.frame = fullSize
        view.contentMode = UIView.ContentMode.scaleAspectFit
        
        for subscriber in session.mSubscribers {
            subscriber.getVideoView().isHidden = true
        }
    }
    
    internal func captureScreen(_ roomId: NSNumber){
        let bounds = view.frame
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      
        let image = compressImage(screenshotImage!)
        
        let base64 = convertImageToBase64String(img: image)
        session.sendSnapshot(base64: base64, roomId: roomId)
        
        if let size = prevSize  {
            view.frame = size
        }
        for subscriber in session.mSubscribers {
            subscriber.getVideoView().isHidden = false
        }
    }

    private func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
    private func compressImage (_ image: UIImage) -> UIImage {

        let actualHeight:CGFloat = image.size.height
        let actualWidth:CGFloat = image.size.width
        let imgRatio:CGFloat = actualWidth/actualHeight
        let maxWidth:CGFloat = 320
        let resizedHeight:CGFloat = maxWidth/imgRatio
        let compressionQuality:CGFloat = 0.5

        let rect:CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        let imageData:Data = img.jpegData(compressionQuality: compressionQuality)!
        UIGraphicsEndImageContext()

        return UIImage(data: imageData)!

    }
    
}
