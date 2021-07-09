//
//  RTCSessionDescription.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//


import WebRTC

private let mRTCSessionDescriptionTypeKey = "type"
private let mRTCSessionDescriptionSdpKey = "sdp"

public extension RTCSessionDescription {
    
     convenience init?(fromJSONDictionary dictionary: [AnyHashable : Any]?) {
        let typeString = dictionary?[mRTCSessionDescriptionTypeKey] as! String
        let type = RTCSessionDescription.self.type(for: typeString)
        let sdp = dictionary?[mRTCSessionDescriptionSdpKey] as! String
        self.init(type: type, sdp: sdp)
    }

     func jsonData() -> Data? {
        let type = RTCSessionDescription.string(for: self.type)
        let json = [
            mRTCSessionDescriptionTypeKey: type,
            mRTCSessionDescriptionSdpKey: sdp
        ]
        return try? JSONSerialization.data(withJSONObject: json, options: [])
    }
}
