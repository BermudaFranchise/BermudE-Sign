# frozen_string_literal: true

class AddEncryptionAndNotificationSupport < ActiveRecord::Migration[8.0]
  def change
    # =========================================================================
    # Notification Preferences for Admin/Team
    # =========================================================================

    # Track whether admin copies have been sent for a submission
    unless column_exists?(:submissions, :admin_notified_at)
      add_column :submissions, :admin_notified_at, :datetime, null: true
    end

    # Track document copy delivery status
    unless column_exists?(:submitters, :documents_sent_at)
      add_column :submitters, :documents_sent_at, :datetime, null: true
    end

    # =========================================================================
    # Encryption tracking — helps with key rotation and audit
    # =========================================================================

    # Mark which storage blobs are encrypted (for migration from unencrypted)
    unless column_exists?(:active_storage_blobs, :encrypted)
      add_column :active_storage_blobs, :encrypted, :boolean, default: false, null: false
    end
  end
end
