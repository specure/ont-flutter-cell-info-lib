package com.specure.nettest.cell_info

import android.annotation.SuppressLint
import android.content.Context
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log
import com.specure.nettest.cell_info.models.SIMInfo
import com.specure.nettest.cell_info.models.SIMInfoResponse
import com.google.gson.Gson

/** Reads the active SIM subscriptions straight from the platform (NetMonster is not involved). */
internal class SimInfoCollector(private val context: Context) {

    /**
     * Never throws: when reading fails the reply is `{"simInfoList":[],"error":"<stack trace>"}`,
     * which is what the Dart side has always received.
     */
    fun collectJson(gson: Gson): String = try {
        gson.toJson(collect())
    } catch (e: Exception) {
        Log.e(TAG, "Error getting SIM info", e)
        val json = gson.toJsonTree(SIMInfoResponse(ArrayList())).asJsonObject
        json.addProperty("error", Log.getStackTraceString(e))
        gson.toJson(json)
    }

    // Permissions are checked by CellInfoPlugin before this is called.
    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION") // mcc, mnc and number are part of the JSON contract
    fun collect(): SIMInfoResponse {
        val subscriptionManager =
            context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val defaultDataSubscriptionId = SubscriptionManager.getDefaultDataSubscriptionId()

        val sims = subscriptionManager.activeSubscriptionInfoList.orEmpty().map { subscription ->
            val simTelephonyManager = telephonyManager.createForSubscriptionId(subscription.subscriptionId)
            SIMInfo(
                carrierName = subscription.carrierName?.toString() ?: UNKNOWN,
                displayName = subscription.displayName?.toString() ?: UNKNOWN,
                mcc = subscription.mcc,
                mnc = subscription.mnc,
                subscriptionInfoNumber = subscription.number,
                subscriptionId = subscription.subscriptionId,
                countryIso = subscription.countryIso,
                networkCountryIso = simTelephonyManager.networkCountryIso,
                roaming = simTelephonyManager.isNetworkRoaming,
                isDefaultDataSubscription = subscription.subscriptionId == defaultDataSubscriptionId,
            )
        }
        return SIMInfoResponse(sims)
    }

    private companion object {
        const val TAG = "CellInfoPlugin"
        const val UNKNOWN = "UNKNOWN"
    }
}
