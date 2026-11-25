package com.specure.nettest.cell_info.models.cdma

import com.specure.nettest.cell_info.models.common.Signal
import java.io.Serializable

class SignalCDMA : Signal(), Serializable {
    var cdmaRssi: Int? = null
    var evdoRssi: Int? = null
    var evdoSnr: Int? = null
    var cdmaEcio: Double? = null
    var evdoEcio: Double? = null
}
