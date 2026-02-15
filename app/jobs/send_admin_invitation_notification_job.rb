# frozen_string_literal: true

class SendAdminInvitationNotificationJob < ApplicationJob
  queue_as :default

  # Notifies admin/manager users when a signing invitation is sent to a signer.
  #
  def perform(submitter_id)
    submitter = Submitter.find_by(id: submitter_id)
    return unless submitter

    account = submitter.submission.template.account
    admin_emails = account_admin_emails(account)

    admin_emails.each do |email|
      begin
        AdminMailer.invitation_sent_notification(
          submitter,
          admin_email: email
        ).deliver_later
      rescue StandardError => e
        Rails.logger.error("[AdminInvitationNotification] Failed for #{email}: #{e.message}")
      end
    end
  end

  private

  def account_admin_emails(account)
    User.joins(:account_accesses)
        .where(account_accesses: { account_id: account.id })
        .where(role: [User::ADMIN_ROLE, User::MANAGER_ROLE])
        .where.not(email: [nil, ''])
        .pluck(:email)
        .uniq
  end
end
