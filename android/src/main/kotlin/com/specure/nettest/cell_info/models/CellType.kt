package com.specure.nettest.cell_info.models

import com.specure.nettest.cell_info.models.cdma.CellCDMA
import com.specure.nettest.cell_info.models.gsm.CellGSM
import com.specure.nettest.cell_info.models.lte.CellLTE
import com.specure.nettest.cell_info.models.nr.CellNR
import com.specure.nettest.cell_info.models.tdscdma.CellTDSCDMA
import com.specure.nettest.cell_info.models.wcdma.CellWCDMA
import java.io.Serializable

class CellType : Serializable {
    var type: String? = null
    var networkType: String? = null
    var cdma: CellCDMA? = null
    var gsm: CellGSM? = null
    var lte: CellLTE? = null
    var nr: CellNR? = null
    var tdscdma: CellTDSCDMA? = null
    var wcdma: CellWCDMA? = null
    var nrAvailable: Boolean? = null
    var enDcAvailable: Boolean? = null
    var nrConnected: Boolean? = null
    var nrConnectionStatus: String? = null
    var nrRejectedReason: String? = null
}
