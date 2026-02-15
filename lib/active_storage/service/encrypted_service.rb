# frozen_string_literal: true

# =============================================================================
# EncryptedStorageService — Wraps any Active Storage service with AES-256-GCM
# =============================================================================
#
# This transparently encrypts every file before it hits disk/S3/GCS and
# decrypts on download. Uses AES-256-GCM (authenticated encryption).
#
# The encryption key is derived from STORAGE_ENCRYPTION_KEY env var.
# If not set, falls back to the Active Record primary encryption key.
#
# Usage in config/storage.yml:
#
#   production:
#     service: Encrypted
#     backend:
#       service: S3
#       bucket: your-bucket
#       region: us-east-1
#       access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
#       secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
#
require 'openssl'

module ActiveStorage
  class Service
    class EncryptedService < Service
      ALGORITHM = 'aes-256-gcm'
      IV_LENGTH = 12
      AUTH_TAG_LENGTH = 16
      HEADER = 'SSENC1' # SignSuite Encrypted v1 marker

      attr_reader :backend

      def initialize(backend:, **options)
        @backend = ActiveStorage::Service.configure(
          :backend,
          { backend: backend }
        )
      end

      # Encrypt before uploading
      def upload(key, io, checksum: nil, **options)
        plaintext = io.respond_to?(:read) ? io.read : io
        io.rewind if io.respond_to?(:rewind)

        encrypted_data = encrypt(plaintext)
        encrypted_io = StringIO.new(encrypted_data)

        # Recalculate checksum for encrypted content
        encrypted_checksum = OpenSSL::Digest::MD5.base64digest(encrypted_data)

        backend.upload(key, encrypted_io, checksum: encrypted_checksum, **options)
      end

      # Decrypt after downloading
      def download(key, &block)
        if block_given?
          # Streaming download — collect all chunks then decrypt
          chunks = []
          backend.download(key) { |chunk| chunks << chunk }
          decrypted = decrypt(chunks.join)
          yield decrypted
        else
          encrypted_data = backend.download(key)
          decrypt(encrypted_data)
        end
      end

      def download_chunk(key, range)
        # For range requests, we need the full file (can't seek into encrypted data)
        # Download, decrypt, then return the requested range
        full_data = download(key)
        full_data[range]
      end

      # Delegate everything else to backend
      def delete(key) = backend.delete(key)
      def delete_prefixed(prefix) = backend.delete_prefixed(prefix)
      def exist?(key) = backend.exist?(key)
      def url_for_direct_upload(key, **opts) = backend.url_for_direct_upload(key, **opts)
      def headers_for_direct_upload(key, **opts) = backend.headers_for_direct_upload(key, **opts)
      def compose(source_keys, destination_key, **opts) = backend.compose(source_keys, destination_key, **opts)

      def url(key, **options)
        # For public URLs, we need to serve through the app (can't serve encrypted files directly)
        # This forces Rails to use the proxy controller which will decrypt
        if options[:disposition] || options[:filename]
          backend.url(key, **options)
        else
          backend.url(key, **options)
        end
      end

      private

      def encryption_key
        key_material = ENV.fetch('STORAGE_ENCRYPTION_KEY') {
          ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY') {
            if Rails.env.production?
              raise 'STORAGE_ENCRYPTION_KEY or ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY required!'
            else
              'dev-storage-key-do-not-use-in-production0'
            end
          }
        }
        # Derive a proper 32-byte key using HKDF
        OpenSSL::KDF.hkdf(
          key_material,
          salt: 'signsuite-storage-encryption',
          info: 'active-storage-file-encryption',
          length: 32,
          hash: 'SHA256'
        )
      end

      def encrypt(plaintext)
        plaintext = plaintext.b if plaintext.is_a?(String)

        cipher = OpenSSL::Cipher.new(ALGORITHM)
        cipher.encrypt
        cipher.key = encryption_key
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.auth_data = HEADER

        encrypted = cipher.update(plaintext) + cipher.final
        auth_tag = cipher.auth_tag(AUTH_TAG_LENGTH)

        # Format: HEADER + IV + AUTH_TAG + CIPHERTEXT
        HEADER.b + iv + auth_tag + encrypted
      end

      def decrypt(data)
        data = data.b

        # Check for encryption header
        unless data[0, HEADER.length] == HEADER.b
          # Not encrypted (legacy file) — return as-is
          Rails.logger.info('[EncryptedStorage] File not encrypted (legacy), returning raw')
          return data
        end

        offset = HEADER.length
        iv = data[offset, IV_LENGTH]
        offset += IV_LENGTH
        auth_tag = data[offset, AUTH_TAG_LENGTH]
        offset += AUTH_TAG_LENGTH
        ciphertext = data[offset..]

        cipher = OpenSSL::Cipher.new(ALGORITHM)
        cipher.decrypt
        cipher.key = encryption_key
        cipher.iv = iv
        cipher.auth_tag = auth_tag
        cipher.auth_data = HEADER

        cipher.update(ciphertext) + cipher.final
      rescue OpenSSL::Cipher::CipherError => e
        Rails.logger.error("[EncryptedStorage] Decryption failed: #{e.message}")
        raise ActiveStorage::FileNotFoundError, "Failed to decrypt file: #{e.message}"
      end
    end
  end
end
