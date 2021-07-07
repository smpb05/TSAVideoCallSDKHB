//
//  TSAVideoCallSubscriberDelegate.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 03.07.2021.
//

protocol TSAVideoCallSubscriberDelegate {
    func onConnected(subscriber: TSAVideoCallSubscriber)
    func onDisconnected(subcriber: TSAVideoCallSubscriber)
    func onError(subscriber: TSAVideoCallSubscriber, error: TSAVideoCallError)
}
