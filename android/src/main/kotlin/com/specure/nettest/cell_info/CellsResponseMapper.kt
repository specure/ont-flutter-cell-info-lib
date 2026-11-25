package com.specure.nettest.cell_info

import com.specure.nettest.cell_info.models.CellData
import com.specure.nettest.cell_info.models.CellType
import com.specure.nettest.cell_info.models.CellsResponse
import com.specure.nettest.cell_info.models.cdma.getCdma
import com.specure.nettest.cell_info.models.gsm.getGsm
import com.specure.nettest.cell_info.models.lte.getLte
import com.specure.nettest.cell_info.models.nr.getNr
import com.specure.nettest.cell_info.models.tdscdma.getTdscdma
import com.specure.nettest.cell_info.models.wcdma.getWcdma
import cz.mroczis.netmonster.core.db.model.NetworkType
import cz.mroczis.netmonster.core.model.cell.CellCdma
import cz.mroczis.netmonster.core.model.cell.CellGsm
import cz.mroczis.netmonster.core.model.cell.CellLte
import cz.mroczis.netmonster.core.model.cell.CellNr
import cz.mroczis.netmonster.core.model.cell.CellTdscdma
import cz.mroczis.netmonster.core.model.cell.CellWcdma
import cz.mroczis.netmonster.core.model.cell.ICell
import cz.mroczis.netmonster.core.model.connection.PrimaryConnection
import cz.mroczis.netmonster.core.model.nr.NrNsaState

/**
 * Turns NetMonster Core models into the response that is serialized for Flutter.
 *
 * This has no Android dependencies, so it runs in plain JVM unit tests. The JSON it produces is
 * the plugin's contract with Dart and is pinned by `CellsResponseContractTest`.
 */
internal object CellsResponseMapper {

    /**
     * @param cells cells as returned by `INetMonster.getCells()`
     * @param networkTypes detected network type per subscription id
     */
    fun map(
        cells: List<ICell>,
        networkTypes: Map<Int, NetworkType>,
        now: () -> Long = System::currentTimeMillis,
    ): CellsResponse {
        val primaryCells = ArrayList<CellType>()
        val neighboringCells = ArrayList<CellType>()
        val cellData = ArrayList<CellData>()

        for (cell in cells) {
            val data = CellData().apply { timestamp = now() }
            val cellType = CellType()

            when (cell) {
                is CellNr -> {
                    cellType.nr = getNr(cell, data)
                    cellType.type = "NR"
                }

                is CellLte -> {
                    cellType.lte = getLte(cell, data)
                    cellType.type = "LTE"
                }

                is CellWcdma -> {
                    cellType.wcdma = getWcdma(cell, data)
                    cellType.type = "WCDMA"
                }

                is CellCdma -> {
                    cellType.cdma = getCdma(cell, data)
                    // Legacy quirk kept for compatibility: CDMA cells have always been reported
                    // with the outer type "WCDMA" (the nested `cdma.type` is "CDMA").
                    cellType.type = "WCDMA"
                }

                is CellGsm -> {
                    cellType.gsm = getGsm(cell, data)
                    cellType.type = "GSM"
                }

                is CellTdscdma -> {
                    cellType.tdscdma = getTdscdma(cell, data)
                    cellType.type = "TDSCDMA"
                }

                else -> continue
            }

            if (cell.connectionStatus is PrimaryConnection) {
                val networkType = networkTypes[cell.subscriptionId]
                // Deliberately "null" (a string) when the type is unknown, as before.
                cellType.networkType = networkType?.technology.toString()

                if ((cell is CellNr || cell is CellLte) && networkType is NetworkType.Nr.Nsa) {
                    val state = networkType.nrNsaState
                    cellType.nrAvailable = state.nrAvailable
                    cellType.enDcAvailable = state.enDcAvailable
                    cellType.nrConnected = state.connection is NrNsaState.Connection.Connected
                    cellType.nrConnectionStatus = nrConnectionStatus(state.connection)
                    cellType.nrRejectedReason = nrRejectedReason(state.connection)
                }
                primaryCells.add(cellType)
            } else {
                neighboringCells.add(cellType)
            }
            cellData.add(data)
        }

        return CellsResponse().apply {
            primaryCellList = primaryCells
            neighboringCellList = neighboringCells
            cellDataList = cellData
        }
    }

    private fun nrConnectionStatus(connection: NrNsaState.Connection): String = when (connection) {
        is NrNsaState.Connection.Connected -> "connected"
        is NrNsaState.Connection.Disconnected -> "disconnected"
        is NrNsaState.Connection.Rejected -> "rejected"
    }

    private fun nrRejectedReason(connection: NrNsaState.Connection): String? = when (connection) {
        is NrNsaState.Connection.Rejected -> connection.reason.toString()
        else -> null
    }
}
