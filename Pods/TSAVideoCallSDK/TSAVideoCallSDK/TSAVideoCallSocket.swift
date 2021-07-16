//
//  TSAVideoCallSocket.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
import Starscream
import CommonCrypto
import WebRTC

enum SignalingChannelState : Int {
    case signalingChannelStateClosed
    case signalingChannelStateOpen
    case signalingChannelStateCreate
    case signalingChannelStateAttach
    case signalingChannelStateJoin
    case signalingChannelStateOffer
    case signalingChannelStateError
}

public protocol TSAVideoCallSocketDelegate: NSObjectProtocol {
    func onPublisherJoined(_ handleId: NSNumber?)
    func onPublisherRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?)
    func subscriberHandleRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?)
    func onLeaving(_ handleId: NSNumber?)
    func onTalking(_ handleId: NSNumber?, dict pluginData: [AnyHashable: Any]?)
    func onStoppedTalking(_ handleId: NSNumber?, dict pluginData: [AnyHashable: Any]?)
    func onError(_ error: TSAVideoCallError)
    func onSocketDisconnected(code: NSNumber, message: String?)
    func onUnpublished(_ handleId: NSNumber?)
}

private let janus = "janus"
private let janusData = "data"


public class TSAVideoCallSocket: NSObject, WebSocketDelegate{
    
    var apiUrl: String
    var roomId: NSNumber
    
    var socket: WebSocket!
    private var keepAliveTimer: Timer?
    
    private var transactionsDict: [String : TSAVideoCallTransaction]!
    private var handleDict: [NSNumber : TSAVideoCallHandle]!
    private var feedDict: [NSNumber : TSAVideoCallHandle]!
    
    private var sessionId: NSNumber?
    
    private var state: SignalingChannelState?
    
    var isConnected = false
    
    public weak var delegate: TSAVideoCallSocketDelegate?
    
    public init(apiUrl: String, roomId: NSNumber) {
        self.apiUrl = apiUrl
        self.roomId = roomId
        super.init()
        
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.timeoutInterval = 5
        request.setValue("janus-protocol", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        socket = WebSocket(request: request, certPinner: nil)
        socket.delegate = self
        keepAliveTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.keepAlive), userInfo: nil, repeats: true)
       
        transactionsDict = [String : TSAVideoCallTransaction]()
        handleDict = [NSNumber : TSAVideoCallHandle]()
        feedDict = [NSNumber : TSAVideoCallHandle]()
    }
    
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            case .disconnected(let reason, let code):
                isConnected = false
                self.delegate?.onSocketDisconnected(code: NSNumber(value: code), message: reason)
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                let json = string.toJSON() as! [String: Any]
                print(json)
                guard let janus = json[janus] as? String else{
                    return
                }
                
                if janus == "success" {
                    let transaction: String! = json["transaction"] as? String
                    let videoCallTransaction: TSAVideoCallTransaction = transactionsDict[transaction]!
                    if (videoCallTransaction.success != nil) {
                        videoCallTransaction.success!(json)
                    }
                    transactionsDict.removeValue(forKey: transaction)
                }else if janus == "error" {
                    if(json["transaction"] != nil){
                        let transaction:String! = json["transaction"] as? String
                        let janusTransaction: TSAVideoCallTransaction = transactionsDict[transaction]!
                        if(janusTransaction.error != nil){
                            janusTransaction.error!(json)
                        }
                        transactionsDict.removeValue(forKey: transaction)
                    }else{
                        print("onError \(json)")
                    }
                    let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.MediaServerError, errorCode:  TSAVideoCallError.ErrorCode.MediaServerError, message: json.description)
                    self.delegate?.onError(error)
                }else if janus == "ack" {
                    print("ack")
                }else {
                    let handle = handleDict?[json["sender"] as! NSNumber]
                    
                    if (handle == nil) {
                        print("handle id is null")
                    }else if(janus == "event") {
                        let plugin:[String: Any] = (json["plugindata"] as! [String: Any]) ["data"] as! [String:Any]
                        
                        if(plugin["videoroom"] as! String == "joined"){
                            handle!.onJoined!(handle!)
                        }
                        
                        if (plugin["videoroom"] as! String == "talking") {
                            let feedId = plugin["id"] as! NSNumber
                            self.delegate?.onTalking(feedDict[feedId]?.handleId, dict: plugin)
                        }
                        
                        if (plugin["videoroom"] as! String == "stopped-talking") {
                            let feedId = plugin["id"] as! NSNumber
                            self.delegate?.onStoppedTalking(feedDict[feedId]?.handleId, dict: plugin)
                        }
                        
                        let array = plugin["publishers"] as? NSArray
                        if(array != nil && array!.count > 0){
                            for case let publisher as [String:Any] in array! {
                                let feed:NSNumber = publisher["id"] as! NSNumber
                                let display:String = publisher["display"] as! String
                                self.subscriberCreateHandle(feed: feed,display: display)
                            }
                        }
                      
                        if(plugin["leaving"] != nil){
                            if let value = plugin["leaving"] as? String {
                                if value == "ok" {
                                    self.delegate?.onLeaving(handle?.handleId)
                                    print("publisher left")
                                }
                            }else{
                                let jHandle = feedDict[plugin["leaving"] as! NSNumber]
                                if(jHandle != nil){
                                    self.delegate?.onLeaving(jHandle?.handleId)
                                    print("subscriber left")
                                }
                            }
                        }
                        
                        if (plugin["unpublished"] != nil) {
                            if let value = plugin["unpublished"] as? String {
                                if value == "ok" {
                                    self.delegate?.onUnpublished(handle?.handleId)
                                    print("publisher unpublished")
                                }
                            }else{
                                let jHandle = feedDict[plugin["unpublished"] as! NSNumber]
                                self.delegate?.onUnpublished(jHandle?.handleId)
                                print("subscriber unpublished")
                            }
                        }
                        
                        if(json["jsep"] != nil){
                            handle?.onRemoteJsep!(handle, json["jsep"] as? [AnyHashable: Any])
                        }
                        
                        
                    }else if (janus == "detached") {
                    }
                }
                
            case .binary(let data):
                print("received data: \(data.count)")
            case .pong(_):
                break
            case .ping(_):
                break
            case .error(let error):
                isConnected = false
                handleError(error)
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                isConnected = false
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                isConnected = true
                self.state = .signalingChannelStateOpen
                createSession()
            }
    }
    
    func createSession(){
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
            self.sessionId = (data?["data"] as! [String: NSNumber])["id"]
            self.keepAliveTimer!.fire()
            self.publisherAttachPlugin()
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.SessionError, errorCode: TSAVideoCallError.ErrorCode.SessionFailed, message: data?.description)
            self.delegate?.onError(error)
        }
        transactionsDict![transaction]  = videoCallTransaction
        let createMessage = [
            "janus" : "create",
            "transaction" : transaction
        ]
        socket.write(string: jsonToString(json: createMessage as AnyObject))
    }
    
    
    func publisherAttachPlugin() {
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
            let handle = TSAVideoCallHandle()
            handle.handleId = (data?["data"] as! [String: NSNumber])["id"]
            handle.onJoined = { handle in
                self.delegate?.onPublisherJoined(handle?.handleId)
            }
            handle.onRemoteJsep = { handle, jsep in
                self.delegate?.onPublisherRemoteJsep(handle?.handleId, dict: jsep)
            }
            self.handleDict![handle.handleId!] = handle
            self.publisherJoinRoom(handle)
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.PublisherError, errorCode: TSAVideoCallError.ErrorCode.PublisherPluginNotAttached, message: data?.description)
            self.delegate?.onError(error)
        }
        transactionsDict![transaction] = videoCallTransaction
        let attachMessage = [
            "janus": "attach",
            "plugin": "janus.plugin.videoroom",
            "transaction": transaction,
            "session_id": sessionId!
            ] as [String : Any]
        
        socket.write(string: jsonToString(json: attachMessage as AnyObject))
    }
    
   public func publisherCreateOffer(_ handleId: NSNumber?, sdp: RTCSessionDescription?) {
        let transaction = randomString(withLength: 12)
        let publish = [
            "request": "configure",
            "audio": NSNumber(value: true),
            "video": NSNumber(value: true)
            ] as [String : Any]

        let type = RTCSessionDescription.string(for: sdp!.type)
        var jsep: [String : Any]? = nil
        if let sdp1 = sdp?.sdp {
            jsep = [
            "type": type,
            "sdp": sdp1
        ]
        }
        var offerMessage: [String : Any]? = nil
        if let jsep = jsep, let handleId = handleId {
            offerMessage = [
            "janus": "message",
            "body": publish,
            "jsep": jsep,
            "transaction": transaction,
            "session_id": sessionId!,
            "handle_id": handleId
        ]
        }
        socket.write(string: jsonToString(json: offerMessage as AnyObject))
    }
    
    func publisherJoinRoom(_ handle: TSAVideoCallHandle?) {
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
            
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.PublisherError, errorCode: TSAVideoCallError.ErrorCode.PublisherFailedToJoinRoom, message: data?.description)
            self.delegate?.onError(error)
        }
        transactionsDict![transaction] = videoCallTransaction
        let body = [
            "request": "join",
            "room": roomId,
            "ptype": "publisher",
            "display": "Unknown"
            ] as [String : Any]
        
        var joinMessage: [String : Any]? = nil
        
        if let handleId = handle?.handleId {
            joinMessage = [
            "janus": "message",
            "transaction": transaction,
            "session_id": sessionId!,
            "handle_id": handleId,
            "body": body
        ]
        }
        
        socket.write(string: jsonToString(json: joinMessage as AnyObject))
    }
    
    public func unpublish(handleId: NSNumber?){
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
    
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.PublisherError, errorCode: TSAVideoCallError.ErrorCode.PublisherFailedToUnpublish, message: data?.description)
            self.delegate?.onError(error)
        }
        let body = [
            "request": "unpublish"
            ] as [String : Any]
        
        transactionsDict?[transaction] = videoCallTransaction
        var configureMessage: [String : Any]? = nil
        
        if let handleId = handleId {
             configureMessage = [
                "janus": "message",
                "body": body,
                "transaction": transaction,
                "session_id": sessionId!,
                "handle_id": handleId
             ]
        }
        
        socket.write(string: jsonToString(json: configureMessage as AnyObject))
    }
    
    
    func subscriberCreateHandle(feed: NSNumber?, display: String?) {
        
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
            let handle = TSAVideoCallHandle()
            handle.handleId = (data?["data"] as! [String:NSNumber])["id"]
            handle.feedId = feed
            handle.display = display

            handle.onRemoteJsep = { handle, jsep in
                self.delegate?.subscriberHandleRemoteJsep(handle?.handleId, dict: jsep)
            }
            
            self.handleDict?[handle.handleId!] = handle
            self.feedDict?[handle.feedId!] = handle
            self.subscriberJoinRoom(handle)
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.SubscriberError, errorCode: TSAVideoCallError.ErrorCode.SubscriberFailedToCreateHandle, message: data?.description)
            self.delegate?.onError(error)
        }
        
        transactionsDict![transaction] = videoCallTransaction
        
        let attachMessage = [
            "janus": "attach",
            "plugin": "janus.plugin.videoroom",
            "transaction": transaction,
            "session_id": sessionId!
            ] as [String : Any]
        
        socket.write(string: jsonToString(json: attachMessage as AnyObject))
    }
    
    func subscriberJoinRoom(_ handle: TSAVideoCallHandle?) {
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.SubscriberError, errorCode: TSAVideoCallError.ErrorCode.SubscriberFailedToJoinRoom, message: data?.description)
            self.delegate?.onError(error)
        }
        transactionsDict?[transaction] = videoCallTransaction
        var body: [String : Any]? = nil
        if let feedId = handle?.feedId {
            body = [
            "request": "join",
            "room": roomId,
            "ptype": "subscriber",
            "feed": feedId
        ]
        }
        var message: [String : Any]? = nil
        if let handleId = handle?.handleId, let body = body {
            message = [
            "janus": "message",
            "transaction": transaction,
            "session_id": sessionId!,
            "handle_id": handleId,
            "body": body
        ]
        }
        socket.write(string: jsonToString(json: message as AnyObject))
    }
    
    public func subscriberCreateAnswer(_ handleId: NSNumber?, sdp: RTCSessionDescription?) {
        let transaction = randomString(withLength: 12)

        let body = [
            "request": "start",
            "room": NSNumber(value: 4321)
            ] as [String : Any]

        let type = RTCSessionDescription.string(for: sdp!.type)

        var jsep: [String : Any]? = nil
        if let sdp1 = sdp?.sdp {
            jsep = [
            "type": type,
            "sdp": sdp1
        ]
        }
        var offerMessage: [String : Any]? = nil
        if let jsep = jsep, let handleId = handleId {
            offerMessage = [
            "janus": "message",
            "body": body,
            "jsep": jsep,
            "transaction": transaction,
            "session_id": sessionId!,
            "handle_id": handleId
        ]
        }

        socket.write(string: jsonToString(json: offerMessage as AnyObject))
    }
    
    public func configureMedia(handleId: NSNumber?, audio: Bool, video: Bool) {
        let transaction = randomString(withLength: 12)
        let videoCallTransaction = TSAVideoCallTransaction()
        videoCallTransaction.tid = transaction
        videoCallTransaction.success = { data in
                
        }
        videoCallTransaction.error = { data in
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.SubscriberError, errorCode: TSAVideoCallError.ErrorCode.PublisherFailedToConfigureMedia, message: data?.description)
            self.delegate?.onError(error)
        }
        
        let body = [
            "request": "configure",
            "audio": audio,
            "video": video
            ] as [String : Any]
        
        transactionsDict?[transaction] = videoCallTransaction
        var configureMessage: [String : Any]? = nil
        
        if let handleId = handleId {
             configureMessage = [
                "janus": "message",
                "body": body,
                "transaction": transaction,
                "session_id": sessionId!,
                "handle_id": handleId
             ]
        }
        socket.write(string: jsonToString(json: configureMessage as AnyObject))
    }
    
    
    func setState(_ state: SignalingChannelState) {
        if self.state == state {
            return
        }
        self.state = state
    }
    
    public func trickleCandidate(_ handleId: NSNumber?, candidate: RTCIceCandidate?) {
        var candidateDict: [String : Any]? = nil
        if let sdp = candidate?.sdp, let sdpMid = candidate?.sdpMid {
            candidateDict = [
            "candidate": sdp,
            "sdpMid": sdpMid,
            "sdpMLineIndex": NSNumber(value: candidate?.sdpMLineIndex ?? 0)
        ]
        }

        var trickleMessage: [String : Any]? = nil
        if let candidateDict = candidateDict, let handleId = handleId {
            trickleMessage = [
            "janus": "trickle",
            "candidate": candidateDict,
            "transaction": randomString(withLength: 12),
            "session_id": sessionId!,
            "handle_id": handleId
        ]
        }

        if let trickleMessage = trickleMessage {
            print("trickle \(trickleMessage)")
        }
        socket.write(string: jsonToString(json: trickleMessage as AnyObject))
    }
    
    public func trickleCandidateComplete(_ handleId: NSNumber?) {
        let candidateDict = [
            "completed": NSNumber(value: true)
        ]
        var trickleMessage: [String : Any]? = nil
        if let handleId = handleId {
            trickleMessage = [
            "janus": "trickle",
            "candidate": candidateDict,
            "transaction": randomString(withLength: 12),
            "session_id": sessionId!,
            "handle_id": handleId
        ]
        }
        socket.write(string: jsonToString(json: trickleMessage as AnyObject))
    }
    
    @objc public func tryToConnect(){
        socket.connect()
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.WebSocketError, errorCode: TSAVideoCallError.ErrorCode.WebSocketError, message: e.message)
            self.delegate?.onError(error)
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.WebSocketError, errorCode: TSAVideoCallError.ErrorCode.WebSocketError, message: e.localizedDescription)
            self.delegate?.onError(error)
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            let error = TSAVideoCallError(errorType: TSAVideoCallError.ErrorType.WebSocketError, errorCode: TSAVideoCallError.ErrorCode.WebSocketError, message: "Unknown error")
            self.delegate?.onError(error)
            print("websocket encountered an error")
        }
    }
    
    func randomString(withLength: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<withLength).map{ _ in letters.randomElement()! })
    }
    
    deinit {
        disconnect()
    }

    func disconnect() {
        if state == .signalingChannelStateClosed || state == .signalingChannelStateError {
            return
        }
        socket!.disconnect()
    }
    
    
    @objc func keepAlive() {
        let dict = [
            "janus": "keepalive",
            "session_id": sessionId!,
            "transaction": randomString(withLength: 12)
            ] as [String : Any]
        socket.write(string: jsonToString(json: dict as AnyObject))
    }
    
    func jsonToString(json: AnyObject) -> String{
        do {
            let data1 =  try JSONSerialization.data(withJSONObject: json)
            let convertedString = String(data: data1, encoding: String.Encoding.utf8)
            return convertedString!
        } catch let myJSONError {
            print(myJSONError)
            return ""
        }
    }
    
    
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
