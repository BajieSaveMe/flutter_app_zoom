//
//  AuthenticateProcessor.swift
//  Runner
//
//  Created by Hubert Wang on 28/08/2020.
//

// Demonstrates performing an Authentication against a previously enrolled user.

// The FaceTec Device SDKs will cancel from the Progress Screen if onProgress() is not called for
// 60 seconds. This provides a failsafe for users getting stuck in the process because of a networking
// issue. If you would like to force users to stay on the Progress Screen for longer than 60 seconds,
// you can write code in the FaceMap or ID Scan Processor to call onProgress() via your own custom logic.
import UIKit
import Foundation
import ZoomAuthentication

class AuthenticateProcessor: NSObject, URLSessionDelegate, ZoomFaceMapProcessorDelegate, ZoomSessionDelegate {
    var zoomFaceMapResultCallback: ZoomFaceMapResultCallback!
    var latestZoomSessionResult: ZoomSessionResult?
    var delegate: ProcessingDelegate
    var isSuccess = false
    
    init(delegate: ProcessingDelegate, fromVC: UIViewController) {
        self.delegate = delegate
        super.init()
        
        NetworkingHelpers.getSessionToken(urlSessionDelegate: self) { (sessionToken) in
            guard let serverSessionToken: String = sessionToken else {
                delegate.onSessionTokenError()
                return
            }
            
            // Launch the ZoOm Session.
            let sessionVC = Zoom.sdk.createSessionVC(delegate: self, faceMapProcessorDelegate: self, serverSessionToken: serverSessionToken)
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
        
        // Create and parse request to ZoOm Server.
        NetworkingHelpers.getAuthenticateResponseFromZoomServer(
            urlSessionDelegate: self,
            zoomSessionResult: zoomSessionResult,
            resultCallback: { nextStep in
                self.delegate.requestInProgress = false
                
                if nextStep == .Succeed {
                    // Dynamically set the success message.
                    ZoomCustomization.setOverrideResultScreenSuccessMessage("Authenticated")
                    zoomFaceMapResultCallback.onFaceMapResultSucceed()
                    self.isSuccess = true
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
    
    // iOS way to get upload progress and update ZoOm UI.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        zoomFaceMapResultCallback.onFaceMapUploadProgress(uploadedPercent: uploadProgress)
    }
    
    // The final callback ZoOm SDK calls when done with everything.
    func onZoomSessionComplete() {
        delegate.onProcessingComplete(isSuccess: isSuccess, zoomSessionResult: latestZoomSessionResult)
    }
}

