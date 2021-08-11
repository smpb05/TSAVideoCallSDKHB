//
//  TSAVideoCallSession.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
import Foundation
import WebRTC
import Alamofire

private let mARDMediaStreamId = "ARDAMS"
private let mARDAudioTrackId = "ARDAMSa0"
private let mARDVideoTrackId = "ARDAMSv0"

public protocol TSAVideoCallSessionDelegate: AnyObject {
    func onConnected(session: TSAVideoCallSession)
    func onDisconnected(session: TSAVideoCallSession)
    func onStreamReceived(session: TSAVideoCallSession, stream: TSAVideoCallStream)
    func onStreamDropped(session: TSAVideoCallSession, stream: TSAVideoCallStream)
    func onMessageReceived(session: TSAVideoCallSession, message: String)
    func onFileReceived(session: TSAVideoCallSession, fileName: String, filePath: String)
    func onError(session: TSAVideoCallSession, error: TSAVideoCallError)
}

public class TSAVideoCallSession: NSObject, TSAVideoCallSocketDelegate, RTCPeerConnectionDelegate, TSAVideoCallBrokerDelegate{
    
    public func onSubscriberStarted(_ room: NSNumber) {
        broker?.sendRemoteStream(room: room)
    }
    
    func onBiometricsEvent(event: String, data: [String : Any]?) {
        if(event == "START_SELFIE"){
            mPublisher?.makeFullScreen()
        }else if(event == "SNAPSHOT"){
            if let roomId = data?["room"] as? NSNumber{
                mPublisher?.captureScreen(roomId)
            }
        }else{
            
        }
        
    }
    
    func onCallEvent(event: String, data: [String : Any]?) {
        if(event == "FINISH"){
            for subscriber in mSubscribers {
                subscriber.delegate?.onDisconnected(subcriber: subscriber)
            }
        }else if(event == "REDIRECT"){
            if let newCallHash = data?["callHash"] as? String{
                self.config.updateCallHash(newCallHash)
            }
            self.connect()
        }else{
            
        }
    }
    
    func onRecordEvent(event: String) {
        if event == "START" {
            websocket.configure(handleId: publisherHandleId, record: true)
        }
    }
    
    func onChatEvent(event: String, data: [String : Any]?) {
        if event == "MESSAGE" {
            if let message = data?["textMessage"] as? String{
                self.sessionDelegate?.onMessageReceived(session: self, message: message)
            }
        }else if event == "FILE" {
            if let name =  data?["filename"] as? String {
                if let path = data?["url"] as? String {
                    self.sessionDelegate?.onFileReceived(session: self, fileName: name, filePath: path)
                }
            }
        }else{}
    }
    
    
    
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
        callStart()
    }
    
    public func subscriberHandleRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?) {
        var tc: TSAVideoCallConnection? = nil
        if let handleId = handleId {
            if(peerConnectionDict.keys.contains(handleId)){
                tc = peerConnectionDict[handleId]
            }else{
                let peerConnection = createPeerConnection()
                tc = TSAVideoCallConnection()
                tc?.connection = peerConnection
                tc?.handleId = handleId
                peerConnectionDict[handleId] = tc
            }
            
            let answerDescription = RTCSessionDescription(fromJSONDictionary: jsep)
            peerConnectionDict[handleId]?.connection?.setRemoteDescription(answerDescription!, completionHandler: { error in
                
            })
            
            let mandatoryConstraints = [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ]
            
            let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            peerConnectionDict[handleId]?.connection?.answer(for: constraints, completionHandler: { sdp, error in
                self.peerConnectionDict[handleId]?.connection?.setLocalDescription(sdp!, completionHandler: { error in })
                    self.websocket.subscriberCreateAnswer(handleId, sdp: sdp)
            })
        }
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
    // broker
    func onConnected() {
        fetchRoomId()
    }
    
    func onDisconnected() {
        
    }
    
    
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
    
    var config: TSAVideoCallConfig
    var broker: TSAVideoCallBrokerSocket? = nil
    var roomId: NSNumber? = nil
    
    public init(config: TSAVideoCallConfig) {
        self.config = config
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        setSpeakerStates(enabled: true)
        RTCInitializeSSL();
        RTCSetupInternalTracer();
    }
    
    private func initBroker(_ url: String, path: String){
        broker = TSAVideoCallBrokerSocket(brokerUrl: url, path: path)
        broker?.brokerDelegate = self
    }
    
    private func initSession(_ roomId: NSNumber){
        websocket = TSAVideoCallSocket(apiUrl: config.getWebSocketMediaServerURL(), roomId: roomId)
        websocket.tryToConnect()
        websocket.delegate = self
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
        localVideoTrack.add(mPublisher!.getVideoView())
        mPublisher?.getCameraPreview().captureSession = source.captureSession
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
        initBroker(config.getWebSocketBrokerURL(), path: config.getWebSocketBrokerPath())
    }
    
    private func disconnect(){
        websocket.disconnect()
        peerConnectionDict.removeAll()
        publisherPeerConnection?.close()
        publisherHandleId = nil
        localVideoTrack = nil
        localAudioTrack = nil
        mPublisher = nil
        mSubscribers.removeAll()
        mSubscribersVideoSize.removeAll()
        broker?.stop()
    
        
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
    
    
    internal func switchCameraPreview(){
        if let session = mPublisher?.getCameraPreview().captureSession {
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
        let array =
           ["stun:stun.l.google.com:19302",
                     "stun:stun1.l.google.com:19302",
                     "stun:stun2.l.google.com:19302",
                     "stun:stun3.l.google.com:19302",
                     "stun:stun4.l.google.com:19302"
        ]
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
        if let room = roomId {
            broker?.sendFinish(room: room)
        }
        disconnect()
    }
    

    
}

extension TSAVideoCallSession{
    func fetchRoomId(){
        
        let headers: HTTPHeaders = ["Authorization": config.getAuthData()]
        let params = ["callHash": config.getCallHash()]
        
        let request = AF.request(config.getWebURL()+"/call/check", method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers)
        request.responseJSON{ response in
            if let data = response.value as? [String: Any]{
                if let status  = data["status"] as? String {
                    if status.caseInsensitiveCompare("OK") == .orderedSame {
                        self.roomId = data["room"] as? NSNumber
                        self.broker?.joinRoom(room: self.roomId!)
                        self.initSession(self.roomId!)
                    }else{
                        let error = TSAVideoCallSDK.TSAVideoCallError(errorType: TSAVideoCallSDK.TSAVideoCallError.ErrorType.SessionError, errorCode: TSAVideoCallSDK.TSAVideoCallError.ErrorCode.WebSocketError, message: "callCheck error: \(String(describing: data["message"]))")
                        self.sessionDelegate?.onError(session: self, error: TSAVideoCallError(error: error))
                    }
                }
            }
            
        }
    }
    
    func callStart(){
        let headers: HTTPHeaders = ["Authorization": config.getAuthData()]
        let params = ["callHash": config.getCallHash(), "appVersion": config.getLibVersion()]
        
        let request = AF.request(config.getWebURL()+"/call/start", method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers)
        request.responseJSON{ response in
            if let data = response.value as? [String: Any]{
                if let status  = data["status"] as? String {
                    if status.caseInsensitiveCompare("OK") == .orderedSame {
                         debugPrint("call start")
                    }else{
                        let error = TSAVideoCallSDK.TSAVideoCallError(errorType: TSAVideoCallSDK.TSAVideoCallError.ErrorType.SessionError, errorCode: TSAVideoCallSDK.TSAVideoCallError.ErrorCode.WebSocketError, message: "callStart error: \(String(describing: data["message"]))")
                        self.sessionDelegate?.onError(session: self, error: TSAVideoCallError(error: error))
                    }
                }
            }
        }
    }
    
    func sendSnapshot(base64: String, roomId: NSNumber){

        let headers: HTTPHeaders = ["Authorization": config.getAuthData()]
        let params = ["room": "\(roomId)", "selfie": base64]
        let request = AF.request(config.getWebURL()+"/file/uploadImages", method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers)
        request.responseJSON{ response in
            if let data = response.value as? [String: Any]{
                if let status  = data["status"] as? String {
                    if status.caseInsensitiveCompare("OK") == .orderedSame {
                         debugPrint("photo sent")
                    }else{
                        let error = TSAVideoCallSDK.TSAVideoCallError(errorType: TSAVideoCallSDK.TSAVideoCallError.ErrorType.SessionError, errorCode: TSAVideoCallSDK.TSAVideoCallError.ErrorCode.SessionFailedToSendSnapshot, message: "uploadImages error: \(String(describing: data["message"]))")
                        self.sessionDelegate?.onError(session: self, error: TSAVideoCallError(error: error))
                    }
                }
            }
        }
    }
}
