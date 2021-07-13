//
//  TSAVideoCallError.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 13.07.2021.
//

import Foundation
import TSAVideoCallSDK

public class TSAVideoCallError{
    private var error: TSAVideoCallSDK.TSAVideoCallError
    
    public init(error: TSAVideoCallSDK.TSAVideoCallError){
        self.error = error
    }
    
    public func getMessage() -> String?{
        return self.error.getErrorMessage()
    }
    
    public func getErrorType() -> String{
        return self.getErrorType()
    }
    
    public func getErrorCode() -> NSNumber{
        return self.getErrorCode()
    }
}
