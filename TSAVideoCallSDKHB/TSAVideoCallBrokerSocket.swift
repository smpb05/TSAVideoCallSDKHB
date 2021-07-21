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
}

class TSAVideoCallBrokerSocket {
    
    public weak var brokerDelegate: TSAVideoCallBrokerDelegate?
    var manager: SocketManager
    var socket: SocketIOClient
    
    init(brokerUrl: String, path: String) {
        manager = SocketManager(socketURL: URL(string: brokerUrl)!, config: [ .version(.two), .compress, .path(path)])
        socket = manager.socket(forNamespace: "/client")
        addHandlers()
    }
    
    
    private func addHandlers(){
        
        self.socket.on(clientEvent: .error){ (data, ack) in
            if let errorStr: String = data[0] as? String{
                debugPrint("error \(errorStr)")
            }
        }
        
        self.socket.once(clientEvent: .connect){ (data, ack) in
            self.brokerDelegate?.onConnected()
            debugPrint("connected once")
        }
        
        self.socket.on("EVENT"){ (data, ack) in
            debugPrint("event \(data)")
        }
        
        self.socket.on(clientEvent: .disconnect){ (data, ack) in
            self.brokerDelegate?.onDisconnected()
            debugPrint("disconnected")
        }
        
        self.socket.connect()

    }
        
    
    func stop() {
        socket.removeAllHandlers()
    }
    
}


