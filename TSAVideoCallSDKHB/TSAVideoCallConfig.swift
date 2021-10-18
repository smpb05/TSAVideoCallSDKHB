//
//  TSAVideoCallConfig.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 14.07.2021.
//

import Foundation

public struct TSAVideoCallConfig{
    
    private var webUrl: String
    private var webSocketMediaServerUrl: String
    private var webSocketBrokerUrl: String
    private var webSocketBrokerPath: String
    private var callHash: String
    private let libVersion = "0.2.6"
    private var authData: String

    public init(webUrl: String, webSocketMediaServerUrl: String, webSocketBrokerUrl: String, webSocketBrokerPath: String, callHash: String, authData: String){
        self.webUrl = webUrl
        self.webSocketMediaServerUrl = webSocketMediaServerUrl
        self.webSocketBrokerUrl = webSocketBrokerUrl
        self.webSocketBrokerPath = webSocketBrokerPath
        self.callHash = callHash
        self.authData = authData
    }
    
    public func getWebURL() -> String{
        return webUrl
    }
    
    public func getWebSocketMediaServerURL() -> String{
        return webSocketMediaServerUrl
    }
    
    public func getWebSocketBrokerURL() -> String{
        return webSocketBrokerUrl
    }
    
    public func getWebSocketBrokerPath() -> String{
        return webSocketBrokerPath
    }
    
    
    public func getCallHash() -> String{
        return callHash
    }
    
    public func getLibVersion() -> String{
        return libVersion
    }
    
    public func getAuthData() -> String{
        return authData
    }
    
    internal mutating func updateCallHash(_ callHash: String){
        self.callHash = callHash
    }
    
}
