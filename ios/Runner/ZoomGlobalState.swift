//
//  ZoomGlobalState.swift
//  Runner
//
//  Created by Hubert Wang on 28/08/2020.
//

import Foundation
import ZoomAuthentication

class ZoomGlobalState {
    static let DeviceLicenseKeyIdentifier = "d5Iqs00YwahDDQGzpPHIfx3DMuDekHvc"
    static let ZoomServerBaseURL = "https://api.zoomauth.com/api/v2/biometrics"
    static let PublicFaceMapEncryptionKey =
        "-----BEGIN PUBLIC KEY-----\n" +
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5PxZ3DLj+zP6T6HFgzzk\n" +
        "M77LdzP3fojBoLasw7EfzvLMnJNUlyRb5m8e5QyyJxI+wRjsALHvFgLzGwxM8ehz\n" +
        "DqqBZed+f4w33GgQXFZOS4AOvyPbALgCYoLehigLAbbCNTkeY5RDcmmSI/sbp+s6\n" +
        "mAiAKKvCdIqe17bltZ/rfEoL3gPKEfLXeN549LTj3XBp0hvG4loQ6eC1E1tRzSkf\n" +
        "GJD4GIVvR+j12gXAaftj3ahfYxioBH7F7HQxzmWkwDyn3bqU54eaiB7f0ftsPpWM\n" +
        "ceUaqkL2DZUvgN0efEJjnWy5y1/Gkq5GGWCROI9XG/SwXJ30BbVUehTbVcD70+ZF\n" +
        "8QIDAQAB\n" +
        "-----END PUBLIC KEY-----"
    
    // Used for bookkeeping around demonstrating enrollment/authentication functionality of ZoOm
    static var randomUsername: String = ""
    static var isRandomUsernameEnrolled = false
    
    // This app can modify the customization to demonstrate different look/feel preferences for ZoOm
    static var currentCustomization: ZoomCustomization = ZoomCustomization()
}
