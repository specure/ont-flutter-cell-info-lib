package com.specure.nettest.cell_info.models

import java.io.Serializable

/** Field names are the JSON keys read by Dart's `SimInfoList`; do not rename them. */
class SIMInfo(
    var carrierName: String? = null,
    var displayName: String? = null,
    var mcc: Int? = null,
    var mnc: Int? = null,
    var subscriptionInfoNumber: String? = null,
    var subscriptionId: Int? = null,
    var countryIso: String? = null,
    var networkCountryIso: String? = null,
    var roaming: Boolean? = null,
    /** True if this SIM is the one used for mobile data in a multi SIM setup. */
    var isDefaultDataSubscription: Boolean? = null,
) : Serializable
