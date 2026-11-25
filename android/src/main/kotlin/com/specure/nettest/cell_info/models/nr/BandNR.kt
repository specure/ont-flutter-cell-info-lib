package com.specure.nettest.cell_info.models.nr

import com.specure.nettest.cell_info.models.common.Band
import java.io.Serializable

class BandNR : Band(), Serializable {
    var downlinkArfcn: Int? = null
    var downlinkFrequency: Int? = null
}
