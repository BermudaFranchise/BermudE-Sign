# frozen_string_literal: true

class EncryptExistingBlobsJob < ApplicationJob
  queue_as :low_priority

  # Re-encrypts existing Active Storage blobs that were uploaded before
  # encryption was enabled. Safe to run multiple times — skips already
  # encrypted blobs.
  #
  # Run with: rails runner 'EncryptExistingBlobsJob.perform_later'
  # Or from console: EncryptExistingBlobsJob.perform_now
  #
  def perform(batch_size: 100)
    return unless encryption_service_active?

    total = 0
    errors = 0

    ActiveStorage::Blob.where(encrypted: false).find_each(batch_size: batch_size) do |blob|
      begin
        re_encrypt_blob(blob)
        total += 1
        Rails.logger.info("[EncryptExistingBlobs] Encrypted blob #{blob.id} (#{blob.filename})")
      rescue StandardError => e
        errors += 1
        Rails.logger.error("[EncryptExistingBlobs] Failed blob #{blob.id}: #{e.message}")
      end
    end

    Rails.logger.info("[EncryptExistingBlobs] Complete: #{total} encrypted, #{errors} errors")
  end

  private

  def encryption_service_active?
    service = ActiveStorage::Blob.service
    service.is_a?(ActiveStorage::Service::EncryptedService) ||
      service.class.name.include?('Encrypted')
  end

  def re_encrypt_blob(blob)
    # Download the raw (unencrypted) content
    raw_content = blob.service.backend.download(blob.key)

    # Check if already encrypted (has our header)
    return if raw_content[0, 6] == 'SSENC1'

    # Upload through the encrypted service (which will encrypt it)
    blob.service.upload(blob.key, StringIO.new(raw_content))

    # Mark as encrypted
    blob.update_column(:encrypted, true)
  end
end
