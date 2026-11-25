package com.specure.nettest.cell_info

import android.annotation.SuppressLint
import android.content.Context
import com.specure.nettest.cell_info.models.CellsResponse
import cz.mroczis.netmonster.core.db.NetworkTypeTable
import cz.mroczis.netmonster.core.db.model.NetworkType
import cz.mroczis.netmonster.core.factory.NetMonsterFactory
import cz.mroczis.netmonster.core.feature.detect.DetectorAosp
import cz.mroczis.netmonster.core.feature.detect.DetectorLteAdvancedNrServiceState

/**
 * The only place that talks to NetMonster Core's Android-dependent API. Everything it returns is
 * handed to [CellsResponseMapper], which is pure and covered by the contract tests.
 */
internal class CellInfoCollector(private val context: Context) {

    // Permissions are checked by CellInfoPlugin before this is called.
    @SuppressLint("MissingPermission")
    fun collect(): CellsResponse {
        val netMonster = NetMonsterFactory.get(context)
        val cells = netMonster.getCells()

        val networkTypes = cells
            .map { it.subscriptionId }
            .distinct()
            .associateWith { subscriptionId ->
                netMonster.getNetworkType(
                    subscriptionId,
                    DetectorLteAdvancedNrServiceState(),
                    // DetectorLteAdvancedPhysicalChannel() and DetectorLteAdvancedCellInfo() were
                    // left out on purpose: they mixed up NR and LTE on dual SIM devices (ISSUES.md).
                    DetectorAosp(), // best to keep last when all other strategies fail
                ) ?: NetworkTypeTable.get(NetworkType.UNKNOWN)
            }

        return CellsResponseMapper.map(cells, networkTypes)
    }
}
