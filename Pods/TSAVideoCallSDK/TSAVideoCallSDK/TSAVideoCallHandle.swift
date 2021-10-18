//
//  TSAVideoCallHandle.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
typealias OnJoined = (TSAVideoCallHandle?) -> Void
typealias OnRemoteJsep = (TSAVideoCallHandle?, [AnyHashable : Any]?) -> Void

class TSAVideoCallHandle: NSObject {
    var handleId: NSNumber?
    var feedId: NSNumber?
    var display: String?
    var onJoined: OnJoined?
    var onRemoteJsep: OnRemoteJsep?
    var onLeaving: OnJoined?
}
