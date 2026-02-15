# frozen_string_literal: true

# =============================================================================
# FieldEncryption — Adds Active Record Encryption to sensitive model fields
# =============================================================================
#
# Include this concern in models that store PII or sensitive data.
# Fields encrypted with `encrypts` are transparently encrypted/decrypted
# at the application level — the database only ever sees ciphertext.
#
# Deterministic encryption (for :email fields) allows querying:
#   Submitter.find_by(email: 'test@example.com')  # still works!
#
# Non-deterministic encryption (for values, names) is more secure
# but doesn't support direct DB queries on the encrypted field.
#
module FieldEncryption
  extend ActiveSupport::Concern

  included do
    # Override in each model to declare which fields to encrypt
  end

  class_methods do
    # Helper to conditionally add encryption (safe for migration period)
    def encrypt_fields(*fields, deterministic: false)
      fields.each do |field|
        encrypts field, deterministic: deterministic
      rescue StandardError => e
        Rails.logger.warn("[FieldEncryption] Could not encrypt #{field} on #{name}: #{e.message}")
      end
    end
  end
end
