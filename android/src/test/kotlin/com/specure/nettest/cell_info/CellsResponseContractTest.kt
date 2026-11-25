package com.specure.nettest.cell_info

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import cz.mroczis.netmonster.core.db.NetworkTypeTable
import cz.mroczis.netmonster.core.db.model.NetworkType
import cz.mroczis.netmonster.core.model.Network
import cz.mroczis.netmonster.core.model.cell.CellCdma
import cz.mroczis.netmonster.core.model.cell.CellGsm
import cz.mroczis.netmonster.core.model.cell.CellLte
import cz.mroczis.netmonster.core.model.cell.CellNr
import cz.mroczis.netmonster.core.model.cell.CellTdscdma
import cz.mroczis.netmonster.core.model.cell.CellWcdma
import cz.mroczis.netmonster.core.model.cell.ICell
import cz.mroczis.netmonster.core.model.connection.NoneConnection
import cz.mroczis.netmonster.core.model.connection.PrimaryConnection
import cz.mroczis.netmonster.core.model.connection.SecondaryConnection
import cz.mroczis.netmonster.core.model.nr.NrNsaState
import cz.mroczis.netmonster.core.model.signal.SignalCdma
import cz.mroczis.netmonster.core.model.signal.SignalGsm
import cz.mroczis.netmonster.core.model.signal.SignalLte
import cz.mroczis.netmonster.core.model.signal.SignalNr
import cz.mroczis.netmonster.core.model.signal.SignalTdscdma
import cz.mroczis.netmonster.core.model.signal.SignalWcdma
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail

/**
 * Pins the JSON the plugin hands to Flutter.
 *
 * Each scenario builds NetMonster Core models (from the commit pinned in netmonster.properties),
 * maps them exactly like the plugin does and compares the JSON with a fixture in
 * `<plugin>/test/fixtures`. The same fixtures are parsed by the Dart tests, so together they
 * prove that a NetMonster Core update did not change what Flutter code receives.
 *
 * After a NetMonster Core update:
 *  - this file not compiling means upstream changed a model the plugin depends on,
 *  - a failing comparison means the JSON for Flutter changed.
 *
 * If a change is intended, regenerate the fixtures with
 * `./gradlew :cell_info:testDebugUnitTest -PupdateFixtures=true` (from example/android) and
 * review the diff.
 */
internal class CellsResponseContractTest {

    @Test
    fun ltePrimaryWithNeighbours() = assertMatchesFixture(
        name = "cells_lte",
        cells = listOf(
            lte(connection = PrimaryConnection()),
            // Neighbours typically come without network and identity.
            CellLte(
                network = null,
                eci = null,
                tac = null,
                pci = 301,
                band = BandFactory.lte(1300),
                aggregatedBands = emptyList(),
                bandwidth = null,
                signal = SignalLte(rssi = null, rsrp = -105.0, rsrq = -14.5, cqi = null, snr = null, timingAdvance = null),
                connectionStatus = NoneConnection(),
                subscriptionId = 1,
                timestamp = null,
            ),
        ),
        networkTypes = mapOf(1 to NetworkTypeTable.get(NetworkType.LTE)),
    )

    @Test
    fun nrNonStandalone() = assertMatchesFixture(
        name = "cells_nr_nsa",
        cells = listOf(
            lte(connection = PrimaryConnection()),
            nr(connection = SecondaryConnection(isGuess = false), nci = null, tac = null),
        ),
        networkTypes = mapOf(
            1 to NetworkType.Nr.Nsa(
                NetworkType.LTE_NR,
                NrNsaState(enDcAvailable = true, nrAvailable = true, connection = NrNsaState.Connection.Connected),
            ),
        ),
    )

    @Test
    fun nrStandalone() = assertMatchesFixture(
        name = "cells_nr_sa",
        cells = listOf(nr(connection = PrimaryConnection())),
        networkTypes = mapOf(1 to NetworkTypeTable.get(NetworkType.NR)),
    )

    @Test
    fun dualSimWithRejectedNr() = assertMatchesFixture(
        name = "cells_dual_sim",
        cells = listOf(
            lte(connection = PrimaryConnection(), subscriptionId = 1),
            wcdma(connection = PrimaryConnection(), subscriptionId = 2),
            gsm(connection = NoneConnection(), subscriptionId = 2),
        ),
        networkTypes = mapOf(
            1 to NetworkType.Nr.Nsa(
                NetworkType.LTE_NR,
                NrNsaState(
                    enDcAvailable = true,
                    nrAvailable = false,
                    connection = NrNsaState.Connection.Rejected(NrNsaState.RejectionReason.RESTRICTED),
                ),
            ),
            2 to NetworkTypeTable.get(NetworkType.HSPAP),
        ),
    )

    @Test
    fun legacyTechnologies() = assertMatchesFixture(
        name = "cells_legacy",
        cells = listOf(
            gsm(connection = PrimaryConnection(), subscriptionId = 1),
            wcdma(connection = PrimaryConnection(), subscriptionId = 2),
            cdma(connection = PrimaryConnection(), subscriptionId = 3),
            // Subscription 4 has no detected network type on purpose.
            tdscdma(connection = PrimaryConnection(), subscriptionId = 4),
        ),
        networkTypes = mapOf(
            1 to NetworkTypeTable.get(NetworkType.EDGE),
            2 to NetworkTypeTable.get(NetworkType.UMTS),
            3 to NetworkTypeTable.get(NetworkType.EVDO_A),
        ),
    )

    @Test
    fun emptyResponse() = assertMatchesFixture(
        name = "cells_empty",
        cells = emptyList(),
        networkTypes = emptyMap(),
    )

    @Test
    fun cellDataCarriesDeviceFields() {
        val response = CellsResponseMapper.map(
            listOf(lte(connection = PrimaryConnection())),
            mapOf(1 to NetworkTypeTable.get(NetworkType.LTE)),
        )
        val fields = response.cellDataList!!.first()!!.javaClass.declaredFields.map { it.name }.toSet()

        // android.os.Build is stubbed in JVM tests, so the values are checked on a device by the
        // integration test; here it is enough that the JSON keys still exist.
        assertTrue(fields.containsAll(DEVICE_KEYS), "CellData lost device fields: ${DEVICE_KEYS - fields}")
    }

    // region scenario building blocks

    private val network = Network.map("231", "01")!!

    private fun lte(connection: cz.mroczis.netmonster.core.model.connection.IConnection, subscriptionId: Int = 1) = CellLte(
        network = network,
        eci = 26_373_121,
        tac = 4021,
        pci = 180,
        band = BandFactory.lte(1300),
        aggregatedBands = emptyList(),
        bandwidth = 20_000,
        signal = SignalLte(rssi = -65, rsrp = -95.0, rsrq = -9.5, cqi = 11, snr = 12.4, timingAdvance = 3),
        connectionStatus = connection,
        subscriptionId = subscriptionId,
        timestamp = 1_700_000_000_000,
    )

    private fun nr(
        connection: cz.mroczis.netmonster.core.model.connection.IConnection,
        nci: Long? = 8_612_167_681,
        tac: Int? = 1401,
    ) = CellNr(
        network = network,
        nci = nci,
        tac = tac,
        pci = 512,
        band = BandFactory.nr(630_048),
        signal = SignalNr(csiRsrp = -91, csiRsrq = -11, csiSinr = 14, ssRsrp = -89, ssRsrq = -10, ssSinr = 17, timingAdvance = 5),
        connectionStatus = connection,
        subscriptionId = 1,
        timestamp = 1_700_000_000_000,
    )

    private fun wcdma(connection: cz.mroczis.netmonster.core.model.connection.IConnection, subscriptionId: Int) = CellWcdma(
        network = network,
        ci = 13_180_203,
        lac = 5021,
        psc = 318,
        band = BandFactory.wcdma(10_588),
        signal = SignalWcdma(rssi = -73, bitErrorRate = 2, ecno = -8, rscp = -84, ecio = -6),
        connectionStatus = connection,
        subscriptionId = subscriptionId,
        timestamp = 1_700_000_000_000,
    )

    private fun gsm(connection: cz.mroczis.netmonster.core.model.connection.IConnection, subscriptionId: Int) = CellGsm(
        network = network,
        cid = 20_441,
        lac = 5021,
        bsic = 43,
        band = BandFactory.gsm(77),
        signal = SignalGsm(rssi = -79, bitErrorRate = 1, timingAdvance = 2),
        connectionStatus = connection,
        subscriptionId = subscriptionId,
        timestamp = 1_700_000_000_000,
    )

    private fun cdma(connection: cz.mroczis.netmonster.core.model.connection.IConnection, subscriptionId: Int) = CellCdma(
        network = null,
        sid = 4139,
        nid = 41,
        bid = 4562,
        lat = 50.0755,
        lon = 14.4378,
        signal = SignalCdma(cdmaRssi = -88, cdmaEcio = -7.5, evdoRssi = -90, evdoEcio = -6.0, evdoSnr = 6),
        connectionStatus = connection,
        subscriptionId = subscriptionId,
        timestamp = 1_700_000_000_000,
    )

    private fun tdscdma(connection: cz.mroczis.netmonster.core.model.connection.IConnection, subscriptionId: Int) = CellTdscdma(
        network = network,
        ci = 13_180_203,
        lac = 5021,
        cpid = 66,
        band = BandFactory.tdscdma(10_080),
        signal = SignalTdscdma(rssi = -75, bitErrorRate = 3, rscp = -86),
        connectionStatus = connection,
        subscriptionId = subscriptionId,
        timestamp = 1_700_000_000_000,
    )

    // endregion

    private fun assertMatchesFixture(name: String, cells: List<ICell>, networkTypes: Map<Int, NetworkType>) {
        // Serialized exactly like CellInfoPlugin does it.
        val actual = normalize(JsonParser.parseString(Gson().toJson(CellsResponseMapper.map(cells, networkTypes))))
        val fixture = File(fixturesDir, "$name.json")

        if (updateFixtures) {
            fixture.parentFile.mkdirs()
            fixture.writeText(prettyGson.toJson(actual) + "\n")
            println("Updated fixture ${fixture.path}")
            return
        }

        if (!fixture.exists()) {
            fail("Missing fixture ${fixture.path}. Generate it with -PupdateFixtures=true")
        }
        val expected = JsonParser.parseString(fixture.readText())
        assertEquals(
            prettyGson.toJson(expected),
            prettyGson.toJson(actual),
            "JSON sent to Flutter changed for scenario '$name' (fixture: ${fixture.path})",
        )
    }

    /** Replaces values that depend on the machine or the clock, so fixtures are reproducible. */
    private fun normalize(json: JsonElement): JsonElement {
        json.asJsonObject.getAsJsonArray("cellDataList").forEach { element ->
            val cellData: JsonObject = element.asJsonObject
            assertTrue(cellData.get("timestamp").asLong > 0, "cellDataList[].timestamp must be set")
            cellData.addProperty("timestamp", 0)
            DEVICE_KEYS.forEach { cellData.remove(it) }
        }
        return json
    }

    private companion object {
        /** `CellData` fields filled from android.os.Build / system properties. */
        val DEVICE_KEYS = setOf(
            "oSVERSION", "rELEASE", "dEVICE", "mODEL", "pRODUCT", "bRAND", "dISPLAY", "cPU_ABI",
            "cPU_ABI2", "uNKNOWN", "hARDWARE", "iD", "mANUFACTURER", "sERIAL", "uSER", "hOST",
        )

        val prettyGson: Gson = GsonBuilder().setPrettyPrinting().create()
        val fixturesDir = File(System.getProperty("cellInfo.fixturesDir") ?: error("cellInfo.fixturesDir is not set"))
        val updateFixtures = System.getProperty("cellInfo.updateFixtures") == "true"
    }
}
