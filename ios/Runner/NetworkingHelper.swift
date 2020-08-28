//
//  NetworkingHelper.swift
//  Runner
//
//  Created by Hubert Wang on 28/08/2020.
//

// Demonstrates calling the FaceTec Managed Testing API and/or ZoOm Server

import UIKit
import Foundation
import ZoomAuthentication

// Possible directives after parsing the result from ZoOm Server
enum UXNextStep {
    case Succeed
    case Retry
    case Cancel
}

// Possible directives after parsing ID Scan result from ZoOm Server.
enum IDScanUXNextStep {
    case Succeed
    case Retry
    case RetryInvalidId
    case Cancel
}

class NetworkingHelpers {
    // Get the Session Token from the server
    class func getSessionToken(urlSessionDelegate: URLSessionDelegate, sessionTokenCallback: @escaping (String?) -> ()) {
        let endpoint = ZoomGlobalState.ZoomServerBaseURL + "/session-token"
        let request = NSMutableURLRequest(url: NSURL(string: endpoint)! as URL)
        request.httpMethod = "GET"
        // Required parameters to interact with the FaceTec Managed Testing API.
        request.addValue(ZoomGlobalState.DeviceLicenseKeyIdentifier, forHTTPHeaderField: "X-Device-License-Key")
        request.addValue(Zoom.sdk.createZoomAPIUserAgentString(""), forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: urlSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            // Ensure the data object is not nil otherwise callback with empty dictionary.
            if let data = data {
                if let responseJSONObj = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: AnyObject] {
                    if((responseJSONObj["data"] as? [String : Any]) != nil
                        && (responseJSONObj["data"] as? [String : Any])?["sessionToken"] as? String != nil)
                    {
                        sessionTokenCallback((responseJSONObj["data"] as? [String : Any])?["sessionToken"] as? String)
                        return
                    }
                }
            }
            sessionTokenCallback(nil)
        })
        task.resume()
    }

    // Set up common parameters needed to communicate to the API.
    class func getCommonParameters(zoomSessionResult: ZoomSessionResult) -> [String : Any] {
        let zoomFaceMapBase64 = zoomSessionResult.faceMetrics?.faceMapBase64;
        
        var parameters: [String : Any] = [:]
        parameters["faceMap"] = zoomFaceMapBase64
        parameters["sessionId"] = zoomSessionResult.sessionId
        
        if let auditTrail = zoomSessionResult.faceMetrics?.auditTrailCompressedBase64 {
            parameters["auditTrailImage"] = auditTrail[0]
        }
        
        // pass the low quality audit trail image
        if let lowQualityAuditTrail = zoomSessionResult.faceMetrics?.lowQualityAuditTrailCompressedBase64 {
            parameters["lowQualityAuditTrailImage"] = lowQualityAuditTrail[0]
        }
        
        return parameters
    }
    
    // Set up parameters needed to communicate to the API for Liveness + Matching (Authenticate).
    class func getAuthenticateParameters(zoomSessionResult: ZoomSessionResult) -> [String : Any] {
        let zoomFaceMapBase64 = zoomSessionResult.faceMetrics?.faceMapBase64;
        
        var parameters: [String : Any] = [:]
        parameters["source"] = ["enrollmentIdentifier": ZoomGlobalState.randomUsername]
        parameters["target"] = ["faceMap": zoomFaceMapBase64]
        parameters["sessionId"] = zoomSessionResult.sessionId
        parameters["performContinuousLearning"] = true
        
        if let auditTrail = zoomSessionResult.faceMetrics?.auditTrailCompressedBase64 {
            parameters["auditTrailImage"] = auditTrail[0]
        }
        
        // pass the low quality audit trail image
        if let lowQualityAuditTrail = zoomSessionResult.faceMetrics?.lowQualityAuditTrailCompressedBase64 {
            parameters["lowQualityAuditTrailImage"] = lowQualityAuditTrail[0]
        }
        
        return parameters
    }
    
    // Set up parameters needed to communicate to the API for Photo ID Match.
    class func getPhotoIDMatchParameters(zoomIDScanResult: ZoomIDScanResult, sessionId: String) -> [String : Any] {
        let zoomIDScanBase64 = zoomIDScanResult.idScanMetrics?.idScanBase64;
        
        var parameters: [String : Any] = [:]
        parameters["enrollmentIdentifier"] = ZoomGlobalState.randomUsername
        parameters["idScan"] = zoomIDScanBase64
        parameters["sessionId"] = sessionId
        
        if let frontImagesCompressedBase64 = zoomIDScanResult.idScanMetrics?.frontImagesCompressedBase64 {
            if frontImagesCompressedBase64.count > 0 {
                parameters["idScanFrontImage"] = frontImagesCompressedBase64[0]
            }
        }
        if let backImagesCompressedBase64 = zoomIDScanResult.idScanMetrics?.backImagesCompressedBase64 {
            if backImagesCompressedBase64.count > 0 {
                parameters["idScanBackImage"] = backImagesCompressedBase64[0]
            }
        }
        
        return parameters
    }
    
    // Makes the actual call to the API.
    // Note that for initial integration this sends to the FaceTec Managed Testing API.
    // After deployment of your own instance of ZoOm Server, this will be your own configurable endpoint.
    class func callToZoomServerForResult(
        endpoint: String,
        parameters: [String: Any],
        sessionId: String,
        urlSessionDelegate: URLSessionDelegate,
        resultCallback: @escaping ([String : AnyObject]) -> ()
    )
    {
        let request = NSMutableURLRequest(url: NSURL(string: endpoint)! as URL)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions(rawValue: 0))
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Required parameters to interact with the FaceTec Managed Testing API.
        request.addValue(ZoomGlobalState.DeviceLicenseKeyIdentifier, forHTTPHeaderField: "X-Device-License-Key")
        request.addValue(Zoom.sdk.createZoomAPIUserAgentString(sessionId), forHTTPHeaderField: "User-Agent")
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: urlSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            // Ensure the data object is not nil otherwise callback with empty dictionary.
            if let data = data {
                if let responseJSONObj = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: AnyObject] {
                    resultCallback(responseJSONObj)
                    return
                }
            }
            resultCallback([:])
        })
        task.resume()
    }
    
    // Create and send the request.  Parse the results and send the caller what the next step should be (Succeed, Retry, or Cancel).
    public class func getLivenessCheckResponseFromZoomServer(
        urlSessionDelegate: URLSessionDelegate,
        zoomSessionResult: ZoomSessionResult,
        resultCallback: @escaping (UXNextStep) -> ()
    )
    {
        let parameters = getCommonParameters(zoomSessionResult: zoomSessionResult)
        
        callToZoomServerForResult(
            endpoint: ZoomGlobalState.ZoomServerBaseURL + "/liveness",
            parameters: parameters,
            sessionId: zoomSessionResult.sessionId,
            urlSessionDelegate: urlSessionDelegate,
            resultCallback: { responseJSONObj in
                let nextStep = ServerResultHelpers.getLivenessNextStep(responseJSONObj: responseJSONObj)
                resultCallback(nextStep)
            }
        )
    }
    
    // Create and send the request.  Parse the results and send the caller what the next step should be (Succeed, Retry, or Cancel).
    public class func getEnrollmentResponseFromZoomServer(
        urlSessionDelegate: URLSessionDelegate,
        zoomSessionResult: ZoomSessionResult,
        resultCallback: @escaping (UXNextStep) -> ()
    )
    {
        var parameters = getCommonParameters(zoomSessionResult: zoomSessionResult)
        parameters["enrollmentIdentifier"] = ZoomGlobalState.randomUsername
        
        callToZoomServerForResult(
            endpoint: ZoomGlobalState.ZoomServerBaseURL + "/enrollment",
            parameters: parameters,
            sessionId: zoomSessionResult.sessionId,
            urlSessionDelegate: urlSessionDelegate,
            resultCallback: { responseJSONObj in
                let nextStep = ServerResultHelpers.getEnrollmentNextStep(responseJSONObj: responseJSONObj)
                resultCallback(nextStep)
            }
        )
    }
    
    // Create and send the request.  Parse the results and send the caller what the next step should be (Succeed, Retry, or Cancel).
    public class func getAuthenticateResponseFromZoomServer(
        urlSessionDelegate: URLSessionDelegate,
        zoomSessionResult: ZoomSessionResult,
        resultCallback: @escaping (UXNextStep) -> ()
    )
    {
        let parameters = getAuthenticateParameters(zoomSessionResult: zoomSessionResult)
        
        callToZoomServerForResult(
            endpoint: ZoomGlobalState.ZoomServerBaseURL + "/match-3d-3d",
            parameters: parameters,
            sessionId: zoomSessionResult.sessionId,
            urlSessionDelegate: urlSessionDelegate,
            resultCallback: { responseJSONObj in
                let nextStep = ServerResultHelpers.getAuthenticateNextStep(responseJSONObj: responseJSONObj)
                resultCallback(nextStep)
            }
        )
    }
    
    // Create and send the request.  Parse the results and send the caller what the next step should be (Succeed, Retry, or Cancel).
    public class func getPhotoIDMatchResponseFromZoomServer(
        urlSessionDelegate: URLSessionDelegate,
        zoomIDScanResult: ZoomIDScanResult,
        resultCallback: @escaping (IDScanUXNextStep) -> ()
    )
    {
        let sessionId = UUID().uuidString
        let parameters = getPhotoIDMatchParameters(zoomIDScanResult: zoomIDScanResult, sessionId: sessionId)
        
        callToZoomServerForResult(
            endpoint: ZoomGlobalState.ZoomServerBaseURL + "/id-check",
            parameters: parameters,
            sessionId: sessionId,
            urlSessionDelegate: urlSessionDelegate,
            resultCallback: { responseJSONObj in
                let nextStep = ServerResultHelpers.getPhotoIDMatchNextStep(responseJSONObj: responseJSONObj)
                resultCallback(nextStep)
            }
        )
    }
}

// Helpers for parsing API response to determine if result was a success vs. user needs retry vs. unexpected (cancel out)
// Developers are encouraged to change API call parameters and results to fit their own
class ServerResultHelpers {
    // if Liveness was Determined, succeed.  Otherwise fail.  Unexpected responses cancel.
    public class func getLivenessNextStep(responseJSONObj: [String: AnyObject]) -> UXNextStep {
        if (responseJSONObj["data"] as? [String : Any])?["livenessStatus"] as? Int == 0 {
            return .Succeed
        }
        else if (responseJSONObj["data"] as? [String : Any])?["livenessStatus"] as? Int == 1 {
            return .Retry
        }
        else {
            return .Cancel
        }
    }
    
    // If isEnrolled and Liveness was Determined, succeed.  Otherwise retry.  Unexpected responses cancel.
    public class func getEnrollmentNextStep(responseJSONObj: [String: AnyObject]) -> UXNextStep {
        if (responseJSONObj["meta"] as? [String : Any])?["code"] as? Int == 200
            && ((responseJSONObj["data"] as? [String : Any])?["isEnrolled"] as? Bool) == true
            && (responseJSONObj["data"] as? [String : Any])?["livenessStatus"] as? Int == 0
        {
            return .Succeed
        }
        else if (responseJSONObj["meta"] as? [String : Any])?["code"] as? Int == 200 &&
            ((responseJSONObj["data"] as? [String : Any])?["isEnrolled"] as? Bool) == false
        {
            return .Retry
        }
        else {
            return .Cancel
        }
    }
    
    // If isEnrolled and Liveness was Determined, succeed.  Otherwise retry.  Unexpected responses cancel.
    public class func getAuthenticateNextStep(responseJSONObj: [String: AnyObject]) -> UXNextStep {
        // if both FaceMaps have Liveness Proven, and Match Level is 10 (1 in 4.2 million), then succeed.  Otherwise retry.  Unexpected responses cancel.
        if (responseJSONObj["meta"] as? [String : Any])?["ok"] as? Bool == true
            && (responseJSONObj["data"] as? [String : Any])?["matchLevel"] as? Int == 10
            && (((responseJSONObj["data"] as? [String : Any])?["sourceFaceMap"] as? [String : Any])?["livenessStatus"] as? Int) == 0
            && (((responseJSONObj["data"] as? [String : Any])?["sourceFaceMap"] as? [String : Any])?["livenessStatus"] as? Int) == 0
        {
            return .Succeed
        }
        else if (responseJSONObj["meta"] as? [String : Any])?["ok"] as? Bool == true
            && (responseJSONObj["data"] as? [String : Any])?["matchLevel"] as? Int != 10 ||
            (((responseJSONObj["data"] as? [String : Any])?["sourceFaceMap"] as? [String : Any])?["livenessStatus"] as? Int) != 0 ||
            (((responseJSONObj["data"] as? [String : Any])?["sourceFaceMap"] as? [String : Any])?["livenessStatus"] as? Int) != 0
        {
            return .Retry
        }
        else {
            return .Cancel
        }
    }
    
    // If Liveness was Determined and 3D FaceMap matches the ID Scan, succeed.  Otherwise retry.  Unexpected responses cancel.
    public class func getPhotoIDMatchNextStep(responseJSONObj: [String: AnyObject]) -> IDScanUXNextStep {
        // If Liveness Proven on FaceMap, and Match Level between FaceMap and ID Photo is non-zero, then succeed.  Otherwise retry.  Unexpected responses cancel.
        if (responseJSONObj["meta"] as? [String : Any])?["ok"] as? Bool == true
            && (responseJSONObj["data"] as? [String : Any])?["livenessStatus"] as? Int == 0
            && (responseJSONObj["data"] as? [String : Any])?["matchLevel"] as? Int != 0
        {
            return .Succeed
        }
        else if (responseJSONObj["data"] as? [String : Any])?["livenessStatus"] as? Int != 0 ||
            (responseJSONObj["data"] as? [String : Any])?["matchLevel"] as? Int == 0
        {
            if ((responseJSONObj["data"] as? [String : Any])?["fullIDStatus"] as? Int == 1) {
                return .RetryInvalidId
            }
            else {
                return .Retry
            }
        }
        else {
            return .Cancel
        }
    }
}
