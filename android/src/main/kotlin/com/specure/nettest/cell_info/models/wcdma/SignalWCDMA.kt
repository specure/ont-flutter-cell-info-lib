package com.specure.nettest.cell_info.models.wcdma

import com.specure.nettest.cell_info.models.common.Signal
import java.io.Serializable

class SignalWCDMA : Signal(), Serializable {
    var rssi: Int? = null
    var bitErrorRate: Int? = null
    var rscp: Int? = null
    var rscpAsu: Int? = null
    var rssiAsu: Int? = null
    var ecno: Int? = null
    var ecio: Int? = null
}
