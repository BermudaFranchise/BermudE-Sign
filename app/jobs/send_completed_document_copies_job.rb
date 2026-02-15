# frozen_string_literal: true

class SendCompletedDocumentCopiesJob < ApplicationJob
  queue_as :default

  # Sends completed signed document copies to:
  #   1. The signer (via existing submitter_mailer#documents_copy_email)
  #   2. All admin/manager users in the account (via admin_mailer)
  #
  # Called after a submission is fully completed (all parties have signed).
  #
  def perform(submission_id)
    submission = Submission.find_by(id: submission_id)
    return unless submission
    return unless submission_fully_completed?(submission)

    account = submission.template.account

    # 1. Send copy to each signer who completed
    send_signer_copies(submission)

    # 2. Send copy to admin/team members
    send_admin_copies(submission, account)
  rescue StandardError => e
    Rails.logger.error("[SendCompletedDocumentCopies] Failed for submission #{submission_id}: #{e.message}")
    raise # Re-raise so Sidekiq retries
  end

  private

  def submission_fully_completed?(submission)
    submission.submitters.all? { |s| s.completed_at.present? || s.declined_at.present? }
  end

  def send_signer_copies(submission)
    submission.submitters.where.not(completed_at: nil).find_each do |submitter|
      next unless submitter.email.present?

      # Check if documents_copy preference is enabled for this template
      preferences = submission.template.preferences || {}
      send_copy = preferences.dig('documents_copy_email_enabled') != false

      if send_copy
        begin
          SubmitterMailer.documents_copy_email(submitter).deliver_later
          Rails.logger.info("[SendCompletedDocumentCopies] Signer copy queued for #{submitter.email}")
        rescue StandardError => e
          Rails.logger.error("[SendCompletedDocumentCopies] Failed signer copy to #{submitter.email}: #{e.message}")
        end
      end
    end
  end

  def send_admin_copies(submission, account)
    # Get all admin and manager users for this account
    admin_emails = account_admin_emails(account)

    admin_emails.each do |email|
      begin
        AdminMailer.submission_completed_email(
          submission,
          recipient_email: email
        ).deliver_later
        Rails.logger.info("[SendCompletedDocumentCopies] Admin copy queued for #{email}")
      rescue StandardError => e
        Rails.logger.error("[SendCompletedDocumentCopies] Failed admin copy to #{email}: #{e.message}")
      end
    end
  end

  def account_admin_emails(account)
    # Find users with admin or manager roles who have email notifications enabled
    users = User.joins(:account_accesses)
                .where(account_accesses: { account_id: account.id })
                .where(role: [User::ADMIN_ROLE, User::MANAGER_ROLE])

    users.filter_map do |user|
      # Check if user has document notification preferences enabled
      prefs = user.user_configs&.find_by(key: 'notification_preferences')
      notify = prefs.nil? || prefs.value.nil? || prefs.value.fetch('completed_documents', true)

      user.email if notify && user.email.present?
    end
  end
end
