package com.specure.nettest.cell_info

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Bridges NetMonster Core to Flutter.
 *
 * Wire contract (must stay stable, see the contract tests):
 *  - channel `cell_info`, method `cell_info` -> JSON string of [com.specure.nettest.cell_info.models.CellsResponse]
 *  - channel `sim_info`, method `sim_info` -> JSON string of [com.specure.nettest.cell_info.models.SIMInfoResponse]
 *  - both return `null` when ACCESS_FINE_LOCATION or READ_PHONE_STATE is not granted
 */
class CellInfoPlugin : FlutterPlugin, MethodCallHandler {
    private var cellInfoChannel: MethodChannel? = null
    private var simInfoChannel: MethodChannel? = null
    private var context: Context? = null
    private var executor: ExecutorService? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val gson = Gson()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        executor = Executors.newSingleThreadExecutor()

        // Both channels share one handler, exactly like the original implementation.
        cellInfoChannel = MethodChannel(binding.binaryMessenger, CHANNEL_CELL_INFO).also {
            it.setMethodCallHandler(this)
        }
        simInfoChannel = MethodChannel(binding.binaryMessenger, CHANNEL_SIM_INFO).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = context
        if (context == null) {
            result.error(ERROR_CODE, "Plugin is not attached to an engine", null)
            return
        }

        when (call.method) {
            METHOD_CELL_INFO -> runWithPermissions(context, result) {
                gson.toJson(CellInfoCollector(context).collect())
            }

            METHOD_SIM_INFO -> runWithPermissions(context, result) {
                SimInfoCollector(context).collectJson(gson)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cellInfoChannel?.setMethodCallHandler(null)
        simInfoChannel?.setMethodCallHandler(null)
        cellInfoChannel = null
        simInfoChannel = null
        executor?.shutdown()
        executor = null
        context = null
    }

    /**
     * Replies with `null` when permissions are missing, otherwise runs [block] off the main thread
     * and replies with its result on the main thread.
     */
    private fun runWithPermissions(context: Context, result: Result, block: () -> String) {
        if (!REQUIRED_PERMISSIONS.all { context.isGranted(it) }) {
            result.success(null)
            return
        }

        val executor = executor
        if (executor == null) {
            result.error(ERROR_CODE, "Plugin is not attached to an engine", null)
            return
        }

        executor.execute {
            try {
                val json = block()
                mainHandler.post { result.success(json) }
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to collect data", t)
                mainHandler.post { result.error(ERROR_CODE, t.message, Log.getStackTraceString(t)) }
            }
        }
    }

    private fun Context.isGranted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private companion object {
        const val TAG = "CellInfoPlugin"
        const val ERROR_CODE = "CELL_INFO_ERROR"

        const val CHANNEL_CELL_INFO = "cell_info"
        const val CHANNEL_SIM_INFO = "sim_info"
        const val METHOD_CELL_INFO = "cell_info"
        const val METHOD_SIM_INFO = "sim_info"

        val REQUIRED_PERMISSIONS = listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_PHONE_STATE,
        )
    }
}
