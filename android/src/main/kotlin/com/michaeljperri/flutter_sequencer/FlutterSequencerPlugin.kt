package com.michaeljperri.flutter_sequencer

import android.content.Context
import android.content.res.AssetManager;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** FlutterSequencerPlugin */
public class FlutterSequencerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_sequencer")
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.applicationContext
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    private lateinit var context : Context

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_sequencer")
      channel.setMethodCallHandler(FlutterSequencerPlugin())
      context = registrar.context()
    }

    init {
      System.loadLibrary("flutter_sequencer")
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "setupAssetManager") {
      setupAssetManager(context.assets)
      result.success(null)
    } else if (call.method == "listAssetDir") {
      val assetDir = call.argument<String>("assetDir")!!
      val extension = call.argument<String>("extension")
      val paths =
        context.assets
          .list("flutter_assets/$assetDir")!!
          .filter { fileName -> fileName.endsWith(".$extension") }
          .map { path -> "$assetDir/$path" }

      result.success(paths)
    } else if (call.method == "listAudioUnits") {
      result.success(emptyList<String>())
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private external fun setupAssetManager(assetManager: AssetManager)
}
