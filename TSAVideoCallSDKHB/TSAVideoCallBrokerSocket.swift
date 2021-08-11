//
//  TSAVideoCallBrokerSocket.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 15.07.2021.
//

import Foundation
import SocketIO

protocol TSAVideoCallBrokerDelegate: AnyObject {
    func onConnected()
    func onDisconnected()
    func onBiometricsEvent(event: String, data: [String: Any]?)
    func onCallEvent(event: String, data: [String: Any]?)
    func onRecordEvent(event: String)
    func onChatEvent(event: String, data: [String: Any]?)
    
}

class TSAVideoCallBrokerSocket {
    
    public weak var brokerDelegate: TSAVideoCallBrokerDelegate?
    var manager: SocketManager
    var socket: SocketIOClient
    
    init(brokerUrl: String, path: String) {
        manager = SocketManager(socketURL: URL(string: brokerUrl)!, config: [.version(.two), .path(path)])
        socket = manager.socket(forNamespace: "/client")
        addHandlers()
    }
    
    
    private func addHandlers(){
        
        self.socket.on(clientEvent: .error){ (data, ack) in
            if let errorStr: String = data[0] as? String{
                debugPrint(errorStr)
            }
        }
        
        self.socket.once(clientEvent: .connect){ (data, ack) in
            self.brokerDelegate?.onConnected()
        }
        
        self.socket.on("event"){ (data, ack) in
            debugPrint("json \(data)")
            if let arr = data as? [[String: Any]]{
                if let event = arr[0]["event"] as? String{
                    
                    if let operation = arr[0]["operation"] as? String {
                        
                        if operation == "BIOMETRICS" {
                            
                            let body = arr[0]["data"] as? [String: Any]
                            self.brokerDelegate?.onBiometricsEvent(event: event, data: body)
                            
                        }else if (operation == "CALL"){
                            
                            let body = arr[0]["data"] as? [String: Any]
                            self.brokerDelegate?.onCallEvent(event: event, data: body)
                            
                        }else if (operation == "RECORD"){
                            
                            self.brokerDelegate?.onRecordEvent(event: event)
                            
                        }else if (operation == "CHAT"){
                            
                            let body = arr[0]["data"] as? [String: Any]
                            self.brokerDelegate?.onChatEvent(event: event, data: body)
                            
                        }else{
                            
                        }
                    }
                }
              
            }
        }
        
        self.socket.on(clientEvent: .disconnect){ (data, ack) in
            self.brokerDelegate?.onDisconnected()
        }
        
        self.socket.connect()

    }
        
    func joinRoom(room: NSNumber){
        let operation = [
           "operation": "ROOM",
           "event": "JOIN",
           "data": "\(room)"
        ] as [String : String]
        self.socket.emit("event", operation)
    }
    
    func sendMessage(room: NSNumber, message: String){
        let data = ["room": room]
        let operation = [
            "operation": "CHAT",
            "event": "MESSAGE",
            "textMessage": message,
            "data": data
        ] as [String: Any]
        
        self.socket.emit("event", operation)
    }
    
    func sendFinish(room: NSNumber){
        let data = ["room": room]
        let operation = [
            "operation": "CALL",
            "event": "FINISH",
            "data": data
        ] as [String: Any]
        
        self.socket.emit("event", operation)
    }
    
    func sendRemoteStream(room: NSNumber){
        let data = ["room": room]
        let operation = [
            "operation": "JANUS",
            "event": "REMOTE_STREAM",
            "data": data
        ] as [String: Any]
        self.socket.emit("event", operation)
    }
    
    func stop() {
        socket.removeAllHandlers()
    }
    
}


