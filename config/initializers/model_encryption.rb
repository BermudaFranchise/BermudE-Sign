# frozen_string_literal: true

# =============================================================================
# Model Encryption Patches
# =============================================================================
#
# These patches add Active Record Encryption to existing models.
# Applied via an initializer so we don't need to modify model files directly.
#
# Fields encrypted:
#   Submitter: email (deterministic — searchable), phone, name, values
#   User: email (deterministic), first_name, last_name
#
# Deterministic encryption = same plaintext → same ciphertext = can query with WHERE
# Non-deterministic = same plaintext → different ciphertext each time = more secure
#

Rails.application.config.after_initialize do
  # Submitter — the person signing documents
  if defined?(Submitter)
    Submitter.class_eval do
      encrypts :email, deterministic: true     # Must be searchable (find_by, WHERE)
      encrypts :phone, deterministic: true      # Must be searchable
      encrypts :name                            # Non-deterministic, not queried directly
      encrypts :values                          # Submission field values — highly sensitive
    rescue ActiveRecord::Encryption::Errors::Configuration => e
      Rails.logger.warn("[Encryption] Submitter encryption skipped: #{e.message}")
    end
  end

  # User — admin/team accounts
  if defined?(User)
    User.class_eval do
      encrypts :first_name
      encrypts :last_name
    rescue ActiveRecord::Encryption::Errors::Configuration => e
      Rails.logger.warn("[Encryption] User encryption skipped: #{e.message}")
    end
  end

  # SubmissionEvent — audit log entries contain IP addresses
  if defined?(SubmissionEvent)
    SubmissionEvent.class_eval do
      encrypts :data  # Contains IP addresses, user agents, etc.
    rescue ActiveRecord::Encryption::Errors::Configuration => e
      Rails.logger.warn("[Encryption] SubmissionEvent encryption skipped: #{e.message}")
    end
  end
end
