package com.specure.nettest.cell_info.models.nr


import com.specure.nettest.cell_info.models.common.Cell
import java.io.Serializable

class CellNR : Cell(), Serializable {
    var nci: Long? = null
    var tac: Int? = null
    var pci: Int? = null
    var bandNR: BandNR? = null
    var signalNR: SignalNR? = null
}

