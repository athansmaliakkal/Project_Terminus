package com.terminus.service.security

import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

/**
 * A utility object for cryptographic operations like calculating checksums.
 * In Kotlin, an 'object' is a singleton, meaning there's only one instance of it,
 * which is perfect for utility classes that don't need to be instantiated.
 */
object CryptoUtils {

    /**
     * Calculates the SHA-256 checksum of a given file.
     *
     * @param file The file to calculate the checksum for.
     * @return A hexadecimal string representing the SHA-256 hash of the file.
     */
    fun calculateSHA256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val inputStream = FileInputStream(file)
        val buffer = ByteArray(8192) // A buffer to read the file in chunks
        var bytesRead: Int

        // Read the file chunk by chunk and update the digest
        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            digest.update(buffer, 0, bytesRead)
        }
        inputStream.close()

        // Convert the byte array hash into a hexadecimal string
        val hashBytes = digest.digest()
        return hashBytes.joinToString("") { "%02x".format(it) }
    }
}
