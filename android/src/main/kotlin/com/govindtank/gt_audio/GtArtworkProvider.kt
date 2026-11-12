package com.govindtank.gt_audio

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/**
 * ContentProvider that serves cached audio artwork to Android Auto and system media sessions.
 */
class GtArtworkProvider : ContentProvider() {

    override fun onCreate(): Boolean = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? = null

    override fun getType(uri: Uri): String {
        val path = uri.path?.lowercase() ?: return "image/jpeg"
        return when {
            path.endsWith(".png") -> "image/png"
            path.endsWith(".webp") -> "image/webp"
            path.endsWith(".gif") -> "image/gif"
            else -> "image/jpeg"
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int = 0

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        val context = context ?: throw FileNotFoundException("Context unavailable")
        val path = uri.path?.removePrefix("/") ?: throw FileNotFoundException("Invalid URI: $uri")

        // Look in cache directory first, then files directory
        val cacheFile = File(context.cacheDir, path)
        if (cacheFile.exists()) {
            return ParcelFileDescriptor.open(cacheFile, ParcelFileDescriptor.MODE_READ_ONLY)
        }

        val filesFile = File(context.filesDir, path)
        if (filesFile.exists()) {
            return ParcelFileDescriptor.open(filesFile, ParcelFileDescriptor.MODE_READ_ONLY)
        }

        val directFile = File(path)
        if (directFile.exists()) {
            return ParcelFileDescriptor.open(directFile, ParcelFileDescriptor.MODE_READ_ONLY)
        }

        throw FileNotFoundException("Artwork file not found: $path")
    }
}
