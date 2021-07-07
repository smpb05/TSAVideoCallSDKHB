//
//  VideoCallViewController.swift
//  TSAVideoCallSDKHB
//
//  Created by smartex on 07.07.2021.
//

import UIKit
class VideoCallViewController: UIViewController, TSAVideoCallSessionDelegate, TSAVideoCallPublisherDelegate, TSAVideoCallSubscriberDelegate  {
    
    // subscriber
    func onConnected(subscriber: TSAVideoCallSubscriber) {
        print("subscriber connected")
    }
    
    func onDisconnected(subcriber: TSAVideoCallSubscriber) {
        print("subscriber disconnected")
    }
    
    func onError(subscriber: TSAVideoCallSubscriber, error: TSAVideoCallError) {
        print("eroor: \(error)")
    }
    
    // publisher
    func onStreamCreated(publisher: TSAVideoCallPublisher) {
        view.addSubview(publisher.getVideoView())
        
    }
    
    func onStreamDestroyed(publisher: TSAVideoCallPublisher) {
        
    }
    
    func onError(publisher: TSAVideoCallPublisher, error: TSAVideoCallError) {
        print("error: \(error)")
    }
    
    // session
    func onConnected(session: TSAVideoCallSession) {
        initializePublisher(session)
    }
    
    func onDisconnected(session: TSAVideoCallSession) {
        
    }
    
    func onStreamReceived(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        initializeSubscriber(session: session, stream: stream)
    }
    
    func onStreamDropped(session: TSAVideoCallSession, stream: TSAVideoCallStream) {
        
    }
    
    func onError(session: TSAVideoCallSession, error: TSAVideoCallError) {
        print("error: \(error)")
    }
    
    
    var session: TSAVideoCallSession?
    var publisher: TSAVideoCallPublisher?
    var subscriber: TSAVideoCallSubscriber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = TSAVideoCallSession(apiUrl: "wss://videoserver.t2m.kz/websocket", roomId: 1234)
        session?.sessionDelegate = self
        session?.connect()
        
        
    }
    
    private func initializePublisher( _ session: TSAVideoCallSession){
        publisher = TSAVideoCallPublisher(session: session)
        if let publisher = publisher{
            session.publish(publisher: publisher)
        }
    }
    
    private func initializeSubscriber(session: TSAVideoCallSession, stream: TSAVideoCallStream){
        subscriber = TSAVideoCallSubscriber(session: session, stream: stream)
        if let view = subscriber?.getVideoView() {
            view.addSubview(view)
        }
        if let subscriber = subscriber{
            session.subscribe(subscriber: subscriber)
        }
    }
    
}
