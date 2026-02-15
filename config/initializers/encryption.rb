# frozen_string_literal: true

# =============================================================================
# Active Record Encryption — Encrypts sensitive data at the application level
# =============================================================================
#
# This ensures that even if someone gains direct database access or dumps the
# DB, sensitive fields (emails, names, phone numbers, submission values, etc.)
# are encrypted and unreadable without the application's master key.
#
# ENV VARS REQUIRED (set in Railway):
#   ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY    — 32-byte hex key
#   ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY — 32-byte hex key (for searchable fields)
#   ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT — random salt string
#
# Generate keys with:
#   ruby -e "require 'securerandom'; 3.times { puts SecureRandom.hex(32) }"
#
Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY') {
    if Rails.env.production?
      raise 'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY must be set in production!'
    else
      'dev-primary-key-do-not-use-in-production-000'
    end
  }

  config.active_record.encryption.deterministic_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY') {
    if Rails.env.production?
      raise 'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY must be set in production!'
    else
      'dev-deterministic-key-do-not-use-in-prod-00'
    end
  }

  config.active_record.encryption.key_derivation_salt = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT') {
    if Rails.env.production?
      raise 'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT must be set in production!'
    else
      'dev-salt-do-not-use-in-production'
    end
  }

  # Support unencrypted reads during migration period
  config.active_record.encryption.support_unencrypted_data = true

  # Extend previous encryption schemes when rotating keys
  config.active_record.encryption.extend_queries = true
end
