//
//  TSAVideoCallSubscriber.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
public class TSAVideoCallSubscriber {
    
    let renderer: TSAVideoCallView = TSAVideoCallView()
    
    public init(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        
    }
    
    public func getVideoView() -> TSAVideoCallView{
        return renderer
    }
}
