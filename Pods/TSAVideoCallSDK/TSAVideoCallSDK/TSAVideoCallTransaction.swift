//
//  TSAVideoCallTransaction.swift
//  TSAVideoCallSDK
//
//  Created by smartex on 02.07.2021.
//

import Foundation

typealias TransactionSuccessBlock = ([String : Any]?) -> Void
typealias TransactionErrorBlock = ([String : Any]?) -> Void

class TSAVideoCallTransaction: NSObject {
    var tid: String?
    var success: TransactionSuccessBlock?
    var error: TransactionErrorBlock?
}
