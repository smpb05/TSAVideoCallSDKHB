//
//  TSAVideoCallSubscriber.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

import TSAVideoCallSDK
class TSAVideoCallSubscriber {
    
    let renderer: TSAVideoCallView = TSAVideoCallView()
    
    init(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        
    }
    
    public func getVideoView() -> TSAVideoCallView{
        return renderer
    }
}
