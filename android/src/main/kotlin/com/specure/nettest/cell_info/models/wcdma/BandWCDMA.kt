package com.specure.nettest.cell_info.models.wcdma

import com.specure.nettest.cell_info.models.common.Band
import java.io.Serializable

class BandWCDMA : Band(), Serializable {
    var downlinkUarfcn: Int? = null
}
