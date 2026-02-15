# frozen_string_literal: true

# =============================================================================
# AdminNotifications — Triggers email notifications to admin/team
# =============================================================================
#
# Include in Submission model to automatically notify admins when:
#   - A submission is fully completed → send document copies
#   - A submitter declines → send decline notification
#
# Invitation notifications are triggered from the controller/mailer level
# (see SendAdminInvitationNotificationJob).
#
module AdminNotifications
  extend ActiveSupport::Concern

  included do
    after_update :check_submission_completion, if: :admin_notifications_enabled?
  end

  private

  def check_submission_completion
    return if admin_notified_at.present?
    return unless all_submitters_done?

    # Mark as notified to prevent duplicate sends
    update_column(:admin_notified_at, Time.current)

    # Queue background job to send copies
    SendCompletedDocumentCopiesJob.perform_later(id)
  end

  def all_submitters_done?
    submitters.all? { |s| s.completed_at.present? || s.declined_at.present? }
  end

  def admin_notifications_enabled?
    # Can be disabled via account config
    account_config = template&.account&.account_configs&.find_by(key: 'admin_notifications')
    return true if account_config.nil?

    account_config.value != false && account_config.value != 'false'
  end
end
