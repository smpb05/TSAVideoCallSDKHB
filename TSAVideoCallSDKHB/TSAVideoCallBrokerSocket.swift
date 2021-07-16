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
    
    init(brokerURL: String) {
        manager = SocketManager(socketURL: URL(string: brokerURL)!, config: [.log(true), .compress])
        socket = manager.defaultSocket
        addHandlers()
        socket.connect()
    }
    
    private func addHandlers(){
        socket.on(clientEvent: .connect) { (data, ack) in
            self.brokerDelegate?.onConnected()
        }
        socket.on(clientEvent: .disconnect){ (data, ack) in
            self.brokerDelegate?.onDisconnected()
        }
        socket.on("event") { (data, ack) in
            print("socket event: \(data.first)")
        }
            
    }
        
    
    func stop() {
        socket.removeAllHandlers()
    }
}
