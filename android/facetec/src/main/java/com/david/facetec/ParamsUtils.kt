package com.david.facetec

import com.facetec.sdk.FaceTecIDScanResult
import com.facetec.sdk.FaceTecSessionResult

class ParamsUtils {
    companion object {
        fun getZoomParams(sessionResult: FaceTecSessionResult): HashMap<String, Any?> {
            val params: HashMap<String, Any?> = HashMap()
            params["faceMapBase64"] = sessionResult.faceScanBase64
//            params["countOfZoomSessionsPerformed"] = zoomSessionResult.countOfZoomSessionsPerformed
            params["sessionId"] = sessionResult.sessionId
            params["sessionStatus"] = sessionResult.status?.ordinal
            params["idType"] = null
            params["idStatus"] = null
            return params
        }

        fun getZoomIdParams(sessionResult: FaceTecSessionResult, idScanResult: FaceTecIDScanResult): HashMap<String, Any?> {
            val params: HashMap<String, Any?> = HashMap()
            params["faceMapBase64"] = sessionResult.faceScanBase64
//            params["countOfZoomSessionsPerformed"] = zoomSessionResult.countOfZoomSessionsPerformed
            params["sessionId"] = sessionResult.sessionId
            params["sessionStatus"] = sessionResult.status?.ordinal
            params["idType"] = idScanResult.idType?.ordinal
            params["idStatus"] = idScanResult.status?.ordinal
            return params
        }
    }
}