//
//  ProcesingDelegate.swift
//  Runner
//
//  Created by Hubert Wang on 28/08/2020.
//

// Helpful interfaces and enums

import Foundation
import ZoomAuthentication

// TODO: Need to write Flutter invocation from Swift
protocol ProcessingDelegate: class {
    func onProcessingComplete(isSuccess: Bool, zoomSessionResult: ZoomSessionResult?)
    func onProcessingComplete(isSuccess: Bool, zoomSessionResult: ZoomSessionResult?, zoomIDScanResult: ZoomIDScanResult?)
    
    func onSessionTokenError()
    
    var requestInProgress: Bool { get set }
}

