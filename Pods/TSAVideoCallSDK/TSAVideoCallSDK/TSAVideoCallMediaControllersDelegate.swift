//
//  TSAVideoCallMediaControllersDelegate.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation
import UIKit

protocol TSAVideoCallMediaControllersViewDelegate {

    func onMediaTap(sender: UIImageView, audio: Bool, video: Bool)
    func onSwitchCamTap(sender: UIImageView)
    func onHangupTap(sender: UIImageView)
    
}
