//
//  PhotoIDMatchProcessor.swift
//  Runner
//
//  Created by Hubert Wang on 28/08/2020.
//

// Demonstrates performing a ZoOm Session, proving Liveness, then scanning the ID and performing a Photo ID Match

// The FaceTec Device SDKs will cancel from the Progress Screen if onProgress() is not called for
// 60 seconds. This provides a failsafe for users getting stuck in the process because of a networking
// issue. If you would like to force users to stay on the Progress Screen for longer than 60 seconds,
// you can write code in the FaceMap or ID Scan Processor to call onProgress() via your own custom logic.
import UIKit
import Foundation
import ZoomAuthentication

class PhotoIDMatchProcessor: NSObject, URLSessionDelegate, ZoomFaceMapProcessorDelegate, ZoomIDScanProcessorDelegate, ZoomSessionDelegate {
    var zoomFaceMapResultCallback: ZoomFaceMapResultCallback!
    var zoomIDScanResultCallback: ZoomIDScanResultCallback!
    var latestZoomSessionResult: ZoomSessionResult?
    var zoomIDScanResult: ZoomIDScanResult?
    var delegate: ProcessingDelegate
    var isSuccess = false
    
    init(delegate: ProcessingDelegate, fromVC: UIViewController) {
        self.delegate = delegate
        super.init()
        
        // For demonstration purposes, generate a new uuid for each Photo ID Match.  Enroll this in the DB and compare against the ID after it is scanned.
        ZoomGlobalState.randomUsername = "ios_sample_app_" + UUID().uuidString
        ZoomGlobalState.isRandomUsernameEnrolled = false
        
        NetworkingHelpers.getSessionToken(urlSessionDelegate: self) { (sessionToken) in
            guard let serverSessionToken: String = sessionToken else {
                delegate.onSessionTokenError()
                return
            }
            
            // Launch the ZoOm Session.
            let sessionVC = Zoom.sdk.createSessionVC(delegate: self, faceMapProcessorDelegate: self, zoomIDScanProcessorDelegate: self, serverSessionToken: serverSessionToken)
            fromVC.present(sessionVC, animated: true, completion: nil)
        }
    }
    
    // Required function that handles calling ZoOm Server to get result and decides how to continue.
    func processZoomSessionResultWhileZoomWaits(zoomSessionResult: ZoomSessionResult, zoomFaceMapResultCallback: ZoomFaceMapResultCallback) {
        self.latestZoomSessionResult = zoomSessionResult
        self.zoomFaceMapResultCallback = zoomFaceMapResultCallback
        
        // cancellation, timeout, etc.
        if zoomSessionResult.status != .sessionCompletedSuccessfully || zoomSessionResult.faceMetrics?.faceMap == nil {
            zoomFaceMapResultCallback.onFaceMapResultCancel();
            return
        }
        
        // Create and parse request to ZoOm Server.  Note here that for Photo ID Match, onFaceMapResultSucceed sends you to the next phase (ID Scan) rather than completing.
        NetworkingHelpers.getEnrollmentResponseFromZoomServer(
            urlSessionDelegate: self,
            zoomSessionResult: zoomSessionResult,
            resultCallback: { nextStep in
                self.delegate.requestInProgress = false
                
                if nextStep == .Succeed {
                    // Dynamically set the success message.
                    ZoomCustomization.setOverrideResultScreenSuccessMessage("Liveness\nConfirmed")
                    zoomFaceMapResultCallback.onFaceMapResultSucceed()
                }
                else if nextStep == .Retry {
                    zoomFaceMapResultCallback.onFaceMapResultRetry()
                }
                else {
                    zoomFaceMapResultCallback.onFaceMapResultCancel()
                }
            }
        )
        self.delegate.requestInProgress = true
        
        // After a short delay, if upload is not complete, update the upload message text to notify the user of the in-progress request.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if self.delegate.requestInProgress {
                let uploadMessage:NSMutableAttributedString = NSMutableAttributedString.init(string: "Still Uploading...")
                zoomFaceMapResultCallback.onFaceMapUploadMessageOverride(uploadMessageOverride: uploadMessage)
            }
        }
    }
    
    // Required function that handles calling ZoOm Server to get result and decides how to continue.
    func processZoomIDScanResultWhileZoomWaits(zoomIDScanResult: ZoomIDScanResult, zoomIDScanResultCallback: ZoomIDScanResultCallback) {
        self.zoomIDScanResult = zoomIDScanResult
        self.zoomIDScanResultCallback = zoomIDScanResultCallback
        
        // cancellation, timeout, etc.
        if zoomIDScanResult.status != .success || zoomIDScanResult.idScanMetrics?.idScanBase64 == nil {
            zoomFaceMapResultCallback.onFaceMapResultCancel();
            return
        }
                
        // Create and parse request to ZoOm Server.
        NetworkingHelpers.getPhotoIDMatchResponseFromZoomServer(
            urlSessionDelegate: self,
            zoomIDScanResult: zoomIDScanResult,
            resultCallback: { nextStep in
                self.delegate.requestInProgress = false
                
                if nextStep == .Succeed {
                    // Dynamically set the success message.
                    ZoomCustomization.setOverrideResultScreenSuccessMessage("Your 3D Face\nMatched Your ID")
                    zoomIDScanResultCallback.onIDScanResultSucceed()
                    self.isSuccess = true
                }
                else if nextStep == .RetryInvalidId {
                    zoomIDScanResultCallback.onIDScanResultRetry(retryMode: .front, unsuccessMessage: "Photo ID\nNot Fully Visible")
                }
                else if nextStep == .Retry {
                    zoomIDScanResultCallback.onIDScanResultRetry(retryMode: .front)
                }
                else {
                    zoomIDScanResultCallback.onIDScanResultCancel()
                }
            }
        )
        self.delegate.requestInProgress = true
        
        // After a short delay, if upload is not complete, update the upload message text to notify the user of the in-progress request.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if self.delegate.requestInProgress {
                let uploadMessage:NSMutableAttributedString = NSMutableAttributedString.init(string: "Still Uploading...")
                zoomIDScanResultCallback.onIDScanUploadMessageOverride(uploadMessageOverride: uploadMessage)
            }
        }
    }
    
    // iOS way to get upload progress and update ZoOm UI.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        if zoomIDScanResultCallback != nil {
            zoomIDScanResultCallback.onIDScanUploadProgress(uploadedPercent: uploadProgress)
        }
        else {
            zoomFaceMapResultCallback.onFaceMapUploadProgress(uploadedPercent: uploadProgress)
        }
    }
    
    // The final callback ZoOm SDK calls when done with everything.
    func onZoomSessionComplete() {
        delegate.onProcessingComplete(isSuccess: isSuccess, zoomSessionResult: latestZoomSessionResult, zoomIDScanResult: zoomIDScanResult)
    }
}

