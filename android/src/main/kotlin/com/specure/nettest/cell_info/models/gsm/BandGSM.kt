package com.specure.nettest.cell_info.models.gsm

import com.specure.nettest.cell_info.models.common.Band
import java.io.Serializable

class BandGSM() : Band(), Serializable {
    var arfcn: Int? = null
}
