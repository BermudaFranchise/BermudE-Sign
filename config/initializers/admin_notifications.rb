# frozen_string_literal: true

# =============================================================================
# Admin Notification Hooks
# =============================================================================
#
# Patches the Submission model to include AdminNotifications concern,
# which triggers email notifications to admin/team when submissions complete.
#
# Also hooks into the submitter invitation flow to notify admins.
#
Rails.application.config.after_initialize do
  # Add completion notification callbacks to Submission
  if defined?(Submission)
    Submission.include(AdminNotifications)
  end

  # Hook into SubmitterMailer to also notify admins on invitation send
  if defined?(SubmitterMailer)
    SubmitterMailer.class_eval do
      # After delivering an invitation email, also notify admins
      after_action :notify_admin_of_invitation, only: [:invitation_email]

      private

      def notify_admin_of_invitation
        return unless @submitter&.id

        SendAdminInvitationNotificationJob.perform_later(@submitter.id)
      rescue StandardError => e
        Rails.logger.warn("[AdminNotification] Failed to queue invitation notification: #{e.message}")
      end
    end
  end
end
