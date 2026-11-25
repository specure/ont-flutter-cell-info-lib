package com.specure.nettest.cell_info.models.lte

import com.specure.nettest.cell_info.models.common.Band
import java.io.Serializable

class BandLTE : Band(), Serializable {
    var downlinkEarfcn: Int? = null
}
