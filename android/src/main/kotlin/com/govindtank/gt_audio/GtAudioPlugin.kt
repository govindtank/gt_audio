package com.govindtank.gt_audio

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin that exposes content provider authority and native helpers for gt_audio.
 */
class GtAudioPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var applicationId: String

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationId = binding.applicationContext.packageName
        channel = MethodChannel(binding.binaryMessenger, "com.govindtank.gt_audio/channel")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getArtworkAuthority" -> {
                result.success("$applicationId.gt_audio.artwork")
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
