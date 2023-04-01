package mapsforge_flutter.storage

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.UriPermission
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException


/** MapsforgeStoragePlugin */
class MapsforgeStoragePlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var result: Result
    private var thisActivity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mapsforge_storage")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        thisActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        thisActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        thisActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        thisActivity = null
    }
    
    // @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        this.result = result

        when (call.method) {
            "existsMap" -> {
                val uriString = call.argument<String>("uriString")

                existsMap(uriString)
            }
            "deleteMap" -> {
                val uriString = call.argument<String>("uriString")

                deleteMap(uriString)
            }
            "hasPermission" -> {
                val uriString = call.argument<String>("uriString")!!
                result.success(hasPermission(uriString))
            }
            "askPermission" -> {
                val permissionType = call.argument<String>("type") ?: "write"
                val filename = call.argument<String>("filename")

                if (permissionType == "read") {
                    askReadPermission()
                } else {
                    askWritePermission(filename)
                }
            }
            "writeMapFile" -> {
                val uriString = call.argument<String>("uriString")!!
                val data = call.argument<ByteArray?>("data")!!

                writeMapFile(uriString, data)
            }
            "getLength" -> {
                val uriString = call.argument<String>("uriString") ?: ""

                readFileLength(uriString)
            }
            "readMapFile" -> {
                val uriString = call.argument<String>("uriString")
                val offset = call.argument<Int>("offset") ?: 0
                val length = call.argument<Int>("length") ?: 0

                readMapFile(uriString, offset, length)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    @SuppressLint("WrongConstant")
    override fun onActivityResult(requestCode: Int, resultCode: Int, result: Intent?): Boolean {
        if (requestCode == REQUESTCODE_WRITE_PERMISSION) {
            if (resultCode == Activity.RESULT_OK) {
                val uri = result?.data ?: throw IllegalArgumentException(
                    "No valid value returned by permission activity"
                )

                val takeFlags: Int = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                thisActivity!!.contentResolver.takePersistableUriPermission(uri, takeFlags)

                this.result.success(uri.toString())
            } else {
                this.result.success(null)
            }

            return true
        } else if (requestCode == REQUESTCODE_READ_PERMISSION) {
            if (resultCode == Activity.RESULT_OK) {
                val uri = result?.data ?: throw IllegalArgumentException(
                    "No valid value returned by permission activity"
                )

                val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION
                thisActivity!!.contentResolver.takePersistableUriPermission(uri, takeFlags)

                this.result.success(uri.toString())
            } else {
                this.result.success(null)
            }

            return true
        }

        return false
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun existsMap(uriString: String?) {
        if (uriString.isNullOrEmpty()) {
            result.error("ArgumentException", "Invalid argument", null)
            return
        }

        val uri = Uri.parse(uriString)
        val fileDocument = DocumentFile.fromSingleUri(thisActivity!!, uri)!!

        result.success(fileDocument.exists())
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun deleteMap(uriString: String?) {
        if (uriString.isNullOrEmpty()) {
            result.error("ArgumentException", "Invalid argument", null)
            return
        }

        val uri = Uri.parse(uriString)
        val fileDocument = DocumentFile.fromSingleUri(thisActivity!!, uri)!!

        if (fileDocument.exists()) {
            fileDocument.delete()
        }

        result.success(true)
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun hasPermission(uriString: String): Boolean {
        val permissions = thisActivity!!.contentResolver.persistedUriPermissions

        for (permission: UriPermission in permissions) {
            if (permission.uri.toString() == uriString) {
                return true
            }
        }

        return false
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun askReadPermission() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
        }

        thisActivity?.startActivityForResult(intent, REQUESTCODE_READ_PERMISSION)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun askWritePermission(filename: String?) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, filename ?: "")
        }

        thisActivity?.startActivityForResult(intent, REQUESTCODE_WRITE_PERMISSION)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun writeMapFile(uriString: String, data: ByteArray?) {
        val fileUri = Uri.parse(uriString)
        val fileDocument = DocumentFile.fromSingleUri(thisActivity!!, fileUri)!!

        if (fileDocument.canWrite()) {
             try {
                val contentResolver = thisActivity!!.contentResolver

                contentResolver.openFileDescriptor(fileUri, "w")?.use { fileDescriptor ->
                    FileOutputStream(fileDescriptor.fileDescriptor).use {
                        it.write(data)
                    }
                }

                result.success(true)
            } catch (e: FileNotFoundException) {
                result.error("FileNotFoundException", e.toString(), null)
            } catch (e: IOException) {
                result.error("IOException", e.toString(), null)
            }
        } else {
            result.error("InvalidFileException", "No write permission for sdcard.", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun readFileLength(uriString: String?) {
        if (uriString.isNullOrEmpty()) {
            result.error("ArgumentException", "Invalid argument", null)
            return
        }

        val fileUri = Uri.parse(uriString)
        val fileDocument = DocumentFile.fromSingleUri(thisActivity!!, fileUri)!!

        if (!fileDocument.exists()) {
            result.error("FileAccessException", "Map file cannot be accessed. It does not exist, or no permission is available.", null)
        } else {
            val length = fileDocument.length()
            result.success(length)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun readMapFile(uriString: String?, offset: Int, length: Int) {
        if (uriString.isNullOrEmpty()) {
            result.error("ArgumentException", "Invalid argument", null)
            return
        }

        val fileUri = Uri.parse(uriString)
        val fileDocument = DocumentFile.fromSingleUri(thisActivity!!, fileUri)!!

        if (!fileDocument.exists()) {
            result.error("FileAccessException", "Map file cannot be accessed. It does not exist, or no permission is available.", null)
        } else {
            try {
                val contentResolver = thisActivity!!.applicationContext.contentResolver

                contentResolver.openFileDescriptor(fileUri, "r")?.use { fileDescriptor ->
                    FileInputStream(fileDescriptor.fileDescriptor).use {
                        val bytes = ByteArray(length)

                        it.skip(offset.toLong())
                        it.read(bytes, 0, length)

                        result.success(bytes)
                    }
                }
            } catch (e: FileNotFoundException) {
                result.error("FileNotFoundException", e.toString(), null)
            } catch (e: IOException) {
                result.error("IOException", e.toString(), null)
            }
        }
    }

    companion object {
        private const val REQUESTCODE_READ_PERMISSION = 0
        private const val REQUESTCODE_WRITE_PERMISSION = 1
    }
}
