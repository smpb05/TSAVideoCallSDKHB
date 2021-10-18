//
//  TSAVideoCallPublisherDelegate.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

public protocol TSAVideoCallPublisherDelegate: AnyObject {
     func onStreamCreated(publisher: TSAVideoCallPublisher)
     func onStreamDestroyed(publisher: TSAVideoCallPublisher)
     func onError(publisher: TSAVideoCallPublisher, error: TSAVideoCallError)
}
