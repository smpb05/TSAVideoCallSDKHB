//
//  TSAVideoCallError.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 13.07.2021.
//

import Foundation

public class TSAVideoCallError{
    
    private var type: ErrorType
    private var code: ErrorCode
    private var message: String?
    
    
    public init(errorType: ErrorType, errorCode: ErrorCode, message: String?){
        self.type = errorType
        self.code = errorCode
        self.message = message
    }
    
    public enum ErrorType: String{
        case SessionError = "SessionError"
        case PublisherError = "PublisherError"
        case SubscriberError = "SubscriberError"
        case MediaServerError = "MediaServerError"
        case WebSocketError = "WebSocketError"
    }
    
    public enum ErrorCode: NSNumber{
        
        case ConnectionFailed = 1001
        case SessionFailed = 1002
        case MediaServerError = 1003
        case PublisherPluginNotAttached = 1004
        case PublisherFailedToJoinRoom = 1005
        case PublisherFailedToUnpublish = 1006
        case SubscriberFailedToCreateHandle = 1007
        case SubscriberFailedToJoinRoom = 1008
        case SubsciberFailedToLeaveRoom = 1009
        case PublisherFailedToConfigureMedia = 1010
        case WebSocketError = 1011
        case SessionFailedToCreateRoom = 1012
        case SessionFailedToCheckRoom = 1013
        case SessionFailedToSendSnapshot = 1014
        case PublisherFailedToConfigureRecord = 1015
    }
    
    public func getErrorType() -> ErrorType{
        return type
    }
    
    public func getErrorCode() -> ErrorCode{
        return code
    }
    
    public func getErrorMessage() -> String?{
        return message
    }
    
}
