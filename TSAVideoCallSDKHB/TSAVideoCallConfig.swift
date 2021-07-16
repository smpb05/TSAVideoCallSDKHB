//
//  TSAVideoCallConfig.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 14.07.2021.
//

import Foundation

public struct TSAVideoCallConfig{
    
    private var webUrl: String = "https://videobank-dev.t2m.kz/broker"
    private var webSocketMediaServerUrl: String = ""
    private var webSocketBrokerUrl: String = "https://videobank-dev.t2m.kz/client"
    private var callHash: String = ""
    private let libVersion = "0.2.3"
    private let authData = "Basic dmlkZW9CYW5rOkhmeUxqdnlTdENidmRqS3M="

    public init(webUrl: String, webSocketMediaServerUrl: String, webSocketBrokerUrl: String, callHash: String){
        self.webUrl = webUrl
        self.webSocketMediaServerUrl = webSocketMediaServerUrl
        self.webSocketBrokerUrl = webSocketBrokerUrl
        self.callHash = callHash
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
    
    public func getCallHash() -> String{
        return callHash
    }
    
    public func getLibVersion() -> String{
        return libVersion
    }
    
    public func getAuthData() -> String{
        return authData
    }
}
