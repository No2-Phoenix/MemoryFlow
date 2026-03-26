package com.memoryflow.app

import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val exifChannel = "memoryflow/exif"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exifChannel)
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")?.trim().orEmpty()
                if (path.isEmpty()) {
                    result.error("invalid_path", "Path is empty", null)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "readGpsFromPath" -> {
                        try {
                            val exif = ExifInterface(path)
                            val latLong = exif.latLong
                            if (latLong == null || latLong.size < 2) {
                                result.success(null)
                            } else {
                                result.success(
                                    mapOf(
                                        "latitude" to latLong[0].toDouble(),
                                        "longitude" to latLong[1].toDouble(),
                                    ),
                                )
                            }
                        } catch (error: Exception) {
                            result.error("read_gps_failed", error.message, null)
                        }
                    }

                    "readLocationNameFromPath" -> {
                        try {
                            val exif = ExifInterface(path)
                            val candidates = listOf(
                                exif.getAttribute(ExifInterface.TAG_IMAGE_DESCRIPTION),
                                exif.getAttribute(ExifInterface.TAG_USER_COMMENT),
                                exif.getAttribute(ExifInterface.TAG_GPS_AREA_INFORMATION),
                                exif.getAttribute(ExifInterface.TAG_GPS_PROCESSING_METHOD),
                            )
                            val text = candidates
                                .asSequence()
                                .mapNotNull { it?.trim() }
                                .firstOrNull { it.isNotEmpty() }
                            result.success(text)
                        } catch (error: Exception) {
                            result.error("read_location_failed", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
