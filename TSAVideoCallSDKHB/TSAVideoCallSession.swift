//
//  TSAVideoCallSession.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import Foundation
import WebRTC

private let mARDMediaStreamId = "ARDAMS"
private let mARDAudioTrackId = "ARDAMSa0"
private let mARDVideoTrackId = "ARDAMSv0"

public protocol TSAVideoCallSessionDelegate: AnyObject {
    func onConnected(session: TSAVideoCallSession)
    func onDisconnected(session: TSAVideoCallSession)
    func onStreamReceived(session: TSAVideoCallSession, stream: TSAVideoCallStream)
    func onStreamDropped(session: TSAVideoCallSession, stream: TSAVideoCallStream)
    func onError(session: TSAVideoCallSession, error: TSAVideoCallError)
}

public class TSAVideoCallSession: NSObject, TSAVideoCallSocketDelegate, RTCPeerConnectionDelegate{
    
    public func onError(_ error: TSAVideoCallSDK.TSAVideoCallError) {
        if error.getErrorType() == TSAVideoCallSDK.TSAVideoCallError.ErrorType.SessionError {
            self.sessionDelegate?.onError(session: self, error: TSAVideoCallError(error: error))
        }
        if error.getErrorType() == TSAVideoCallSDK.TSAVideoCallError.ErrorType.PublisherError {
            mPublisher?.delegate?.onError(publisher: mPublisher!, error: TSAVideoCallError(error: error))
        }
        if error.getErrorType() == TSAVideoCallSDK.TSAVideoCallError.ErrorType.SubscriberError {
            self.sessionDelegate?.onError(session: self, error: TSAVideoCallError(error: error))
        }
    }
    
   
    public func onUnpublished(_ handleId: NSNumber?) {
        if(handleId == self.publisherHandleId){
            mPublisher?.delegate?.onStreamDestroyed(publisher: mPublisher!)
        } else {
            for subscriber in mSubscribers {
                if subscriber.getHandleId() as? NSNumber == handleId {
                    self.sessionDelegate?.onStreamDropped(session: self, stream: subscriber.getTSAVideoCallStream()!)
                    break
                }
            }
        }
        
    }
   
    
    public func onSocketDisconnected(code: NSNumber, message: String?) {
        self.sessionDelegate?.onDisconnected(session: self)
    }
    
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        var mhandleId: AnyHashable?
        for key in peerConnectionDict{
            let tc: TSAVideoCallConnection = key.value
            if peerConnection == tc.connection {
                mhandleId = key.key
                break
            }
        }

        DispatchQueue.main.async(execute: {
            if stream.videoTracks.count != 0{
                let tStream = TSAVideoCallStream(handleId: mhandleId, stream: stream)
                self.sessionDelegate?.onStreamReceived(session: self, stream: tStream)
            }
        })
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        var handleId: NSNumber?
        for key in peerConnectionDict {
            let tc: TSAVideoCallConnection = key.value
            if peerConnection == tc.connection {
                handleId = tc.handleId
                break
            }
        }
        if candidate != nil {
            websocket.trickleCandidate(handleId, candidate: candidate)
        } else {
            websocket.trickleCandidateComplete(handleId)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    public func onPublisherJoined(_ handleId: NSNumber?) {
        self.publisherHandleId = handleId
        self.sessionDelegate?.onConnected(session: self)
    }
    
    public func onPublisherRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?) {
        var tc: TSAVideoCallConnection? = nil
        if let handleId = handleId {
            tc = peerConnectionDict[handleId]
        }
        let answerDescription = RTCSessionDescription(fromJSONDictionary: jsep)
        tc?.connection!.setRemoteDescription(answerDescription!, completionHandler: { error in
        })
        mPublisher?.delegate?.onStreamCreated(publisher: mPublisher!)
    }
    
    public func subscriberHandleRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?) {
        let peerConnection = createPeerConnection()
        let tc = TSAVideoCallConnection()
        tc.connection = peerConnection
        tc.handleId = handleId
        if let handleId = handleId {
            peerConnectionDict[handleId] = tc
        }
        let answerDescription = RTCSessionDescription(fromJSONDictionary: jsep)
        peerConnection?.setRemoteDescription(answerDescription!, completionHandler: { error in
        })
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        peerConnection!.answer(for: constraints, completionHandler: { sdp, error in
            peerConnection!.setLocalDescription(sdp!, completionHandler: { error in
            })
            self.websocket.subscriberCreateAnswer(handleId, sdp: sdp)
        })
    }
    
    public func onLeaving(_ handleId: NSNumber?) {
        var tc: TSAVideoCallConnection? = nil
        if let handleId = handleId {
            tc = peerConnectionDict[handleId]
        }
        tc?.connection!.close()
        tc?.connection = nil
        tc?.videoTrack = nil
        tc?.videoView?.renderFrame(nil)
        tc?.videoView!.removeFromSuperview()
        peerConnectionDict.removeValue(forKey: handleId)
        for subscriber in mSubscribers {
            if handleId == subscriber.getHandleId() as? NSNumber {
                subscriber.delegate?.onDisconnected(subcriber: subscriber)
            }
        }
    }
    
    public func onTalking(_ handleId: NSNumber?, dict pluginData: [AnyHashable : Any]?) {
        
    }
    
    public func onStoppedTalking(_ handleId: NSNumber?, dict pluginData: [AnyHashable : Any]?) {
        
    }
    
    
    var apiUrl: String
    var roomId: NSNumber
    public weak var sessionDelegate: TSAVideoCallSessionDelegate?
    
    var websocket: TSAVideoCallSocket!
    var peerConnectionDict = [AnyHashable : TSAVideoCallConnection]()
    var factory: RTCPeerConnectionFactory = RTCPeerConnectionFactory()
    
    var publisherPeerConnection: RTCPeerConnection? = nil
    var publisherHandleId: NSNumber? = nil
    var localVideoTrack: RTCVideoTrack? = nil
    var localAudioTrack: RTCAudioTrack? = nil
    var width: Float? = nil
    var height: Float? = nil
    
    var mPublisher: TSAVideoCallPublisher?
    var mSubscribers: [TSAVideoCallSubscriber] = []
    var mSubscribersVideoSize = [RTCEAGLVideoView : CGSize]()
    
    public init(apiUrl: String, roomId: NSNumber) {
        self.apiUrl = apiUrl
        self.roomId = roomId
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        setSpeakerStates(enabled: true)
        websocket = TSAVideoCallSocket(apiUrl: apiUrl, roomId: roomId)

        RTCInitializeSSL();
        RTCSetupInternalTracer();
 
    }
    
    func createLocalAudioTrack() -> RTCAudioTrack? {
        let constraints = defaultMediaAudioConstraints()
        let source = factory.audioSource(with: constraints)
        let track = factory.audioTrack(with: source, trackId: mARDAudioTrackId)
        return track
    }
    
    func createLocalVideoTrack(useBackCamera: Bool) -> RTCVideoTrack? {
        let cameraConstraints = RTCMediaConstraints(mandatoryConstraints: (currentMediaConstraint() as! [String : String]), optionalConstraints: nil)
        let source = factory.avFoundationVideoSource(with: cameraConstraints)
        source.useBackCamera = useBackCamera
        let localVideoTrack = factory.videoTrack(with: source, trackId: mARDVideoTrackId)
        mPublisher?.getVideoView().captureSession = source.captureSession
        return localVideoTrack
    }
    
    func currentMediaConstraint() -> [AnyHashable : Any]? {
        var mediaConstraintsDictionary: [AnyHashable : Any]? = nil
        let widthConstraint = "\(String(describing: mPublisher?.getVideoView().frame.width))"
        let heightConstraint = "\(String(describing: mPublisher?.getVideoView().frame.height))"
        let frameRateConstrait = "20"
        if widthConstraint != "" && heightConstraint != "" {
            mediaConstraintsDictionary = [
            kRTCMediaConstraintsMinWidth: widthConstraint,
            kRTCMediaConstraintsMinHeight: heightConstraint,
            kRTCMediaConstraintsMaxFrameRate: frameRateConstrait
            ]
        }
        return mediaConstraintsDictionary
    }
    
    func setSpeakerStates(enabled: Bool)
    {
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.videoChat)
        if enabled {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } else {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        }
        try? session.setActive(true)
    }
    
    @objc func didSessionRouteChange(_ notification: Notification?) {
        guard let info = notification?.userInfo,
        let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: value) else {
                return
        }
        switch reason {
        case .categoryChange:
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        default:
            break
        }
    }
    
    public func connect(){
        websocket.tryToConnect()
        websocket.delegate = self
    }
    
    public func publish(publisher: TSAVideoCallPublisher){
        mPublisher = publisher
        createPublisherPeerConnection()
        offerPeerConnection(publisherHandleId)
    }
    
    public func subscribe(subscriber: TSAVideoCallSubscriber){
        mSubscribers.append(subscriber)
        let remoteVideoTrack = subscriber.getStream().videoTracks[0]
        var connection: TSAVideoCallConnection?
        for key in peerConnectionDict{
            if key.key == subscriber.getHandleId() {
                connection = key.value
                break
            }
        }
        remoteVideoTrack.add(subscriber.getVideoView())
        connection?.videoTrack = remoteVideoTrack
        connection?.videoView = subscriber.getVideoView()
        subscriber.delegate?.onConnected(subscriber: subscriber)
    }
    
    
    internal func switchCamera(){
        if let session = mPublisher?.getVideoView().captureSession {
            guard let cureentCameraInput: AVCaptureInput = session.inputs.first else {
                return
            }
            session.beginConfiguration()
            session.removeInput(cureentCameraInput)
            var newCamera: AVCaptureDevice! = nil
            if let input = cureentCameraInput as? AVCaptureDeviceInput{
                if (input.device.position == .back) {
                    newCamera = cameraWithPosition(position: .front)
                }else{
                    newCamera = cameraWithPosition(position: .back)
                }
            }
            var err: NSError?
            var newVideoInput: AVCaptureDeviceInput!
            do {
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            }catch let error as NSError {
                err = error
                newVideoInput = nil
            }
            if newVideoInput == nil || err != nil {
            }else{
                session.addInput(newVideoInput)
            }
            
            session.commitConfiguration()
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice?{
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices{
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    
    internal func onMediaTap(audio: Bool, video: Bool) {
        if audio {
            localAudioTrack?.isEnabled = true
        }else{
            localAudioTrack?.isEnabled = false
        }
        
        if video {
            localVideoTrack?.isEnabled = true
        }else{
            localVideoTrack?.isEnabled = false
        }
        
        websocket.configureMedia(handleId: publisherHandleId, audio: audio, video: video)
    }
    
    
    func createPublisherPeerConnection() {
        localVideoTrack = createLocalVideoTrack(useBackCamera: false)
        localAudioTrack = createLocalAudioTrack()
        publisherPeerConnection = createPeerConnection()
        createAudioSender(publisherPeerConnection)
        createVideoSender(publisherPeerConnection)
    }
    
    func createPeerConnection() -> RTCPeerConnection? {
        let constraints = defaultPeerConnectionConstraints()
        let config = RTCConfiguration()
        let iceServers = [defaultSTUNServer()!]
        config.iceServers = iceServers
        config.iceTransportPolicy = RTCIceTransportPolicy.all
        let peerConnection = factory.peerConnection(with: config, constraints: constraints!, delegate: self)
        return peerConnection
    }
    
    func defaultSTUNServer() -> RTCIceServer? {
        let array = ["stun:stun.l.google.com:19302",
                     "stun:stun1.l.google.com:19302",
                     "stun:stun2.l.google.com:19302",
                     "stun:stun3.l.google.com:19302",
                     "stun:stun4.l.google.com:19302"]
        return RTCIceServer(urlStrings: array)
    }
    
    func createAudioSender(_ peerConnection: RTCPeerConnection?) -> RTCRtpSender? {
        let sender = peerConnection?.sender(withKind: kRTCMediaStreamTrackKindAudio, streamId: mARDMediaStreamId)
        if (localAudioTrack != nil) {
            sender?.track = localAudioTrack
        }
        return sender
    }
    
    func createVideoSender(_ peerConnection: RTCPeerConnection?) -> RTCRtpSender? {
        let sender = peerConnection?.sender(withKind: kRTCMediaStreamTrackKindVideo, streamId: mARDMediaStreamId)
        if (localVideoTrack != nil) {
            sender?.track = localVideoTrack
        }
        return sender
    }
    
    func offerPeerConnection(_ handleId: NSNumber?) {
        
        let connection = TSAVideoCallConnection()
        connection.connection = publisherPeerConnection
        connection.handleId = handleId
        if let handleId = handleId {
            peerConnectionDict[handleId] = connection
        }
        
        publisherPeerConnection!.offer(for: defaultOfferConstraints()!, completionHandler: { sdp, error in
            self.publisherPeerConnection!.setLocalDescription(sdp!, completionHandler: { error in
                self.websocket.publisherCreateOffer(handleId, sdp: sdp!)
            })
        })
        
    }
    
    func defaultMediaAudioConstraints() -> RTCMediaConstraints? {
        let mandatoryConstraints = [
            kRTCMediaConstraintsLevelControl: kRTCMediaConstraintsValueFalse
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return constraints
    }
    
    
    func defaultPeerConnectionConstraints() -> RTCMediaConstraints? {
        let optionalConstraints = [
            "DtlsSrtpKeyAgreement": "true"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
        return constraints
    }
    
    func defaultOfferConstraints() -> RTCMediaConstraints? {
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return constraints
    }
    
    internal func hangup(){
        websocket.unpublish(handleId: publisherHandleId)
    }
}
