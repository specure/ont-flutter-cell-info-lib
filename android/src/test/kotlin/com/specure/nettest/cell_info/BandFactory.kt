package com.specure.nettest.cell_info

import cz.mroczis.netmonster.core.db.BandTableGsm
import cz.mroczis.netmonster.core.db.BandTableLte
import cz.mroczis.netmonster.core.db.BandTableNr
import cz.mroczis.netmonster.core.db.BandTableTdscdma
import cz.mroczis.netmonster.core.db.BandTableWcdma

/**
 * Bands for the contract scenarios.
 *
 * Instances come from NetMonster Core's own tables (so the tests keep compiling when upstream adds
 * constructor parameters), but number and name are overridden with fixed values: the contract
 * tests are about the shape of the JSON, not about upstream's band database.
 */
internal object BandFactory {
    fun lte(earfcn: Int) = BandTableLte.map(earfcn).copy(number = 3, name = "1800")

    fun nr(arfcn: Int) = BandTableNr.map(arfcn).copy(downlinkFrequency = 3_450_720, number = 78, name = "3500")

    fun wcdma(uarfcn: Int) = BandTableWcdma.map(uarfcn).copy(number = 1, name = "2100")

    fun gsm(arfcn: Int) = BandTableGsm.map(arfcn, mcc = null).copy(number = 900, name = "900")

    fun tdscdma(uarfcn: Int) = BandTableTdscdma.map(uarfcn, mcc = null).copy(number = 34, name = "2000")
}
