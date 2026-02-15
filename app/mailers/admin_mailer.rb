# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  # Sends a copy of the completed signed document to the admin/team
  #
  # Called after a submission is fully completed (all signers done).
  # Attaches the final signed PDF + audit trail.
  #
  def submission_completed_email(submission, recipient_email:)
    @submission = submission
    @template = submission.template
    @submitters = submission.submitters.order(:completed_at)
    @account = @template.account

    # Attach completed documents
    submission.submitters.each do |submitter|
      next unless submitter.completed_at?

      submitter.documents.each do |document|
        attachments[document.filename.to_s] = download_blob(document)
      end
    end

    # Attach audit trail if available
    audit_trail = submission.audit_trail
    if audit_trail&.attached?
      attachments['audit_trail.pdf'] = download_blob(audit_trail)
    end

    mail(
      to: recipient_email,
      subject: "✅ Document Signed: #{@template.name}",
      reply_to: reply_to_address
    )
  end

  # Sends notification when a new signing invitation is sent out
  #
  def invitation_sent_notification(submitter, admin_email:)
    @submitter = submitter
    @submission = submitter.submission
    @template = @submission.template

    mail(
      to: admin_email,
      subject: "📤 Signing Invitation Sent: #{@template.name} → #{@submitter.email}",
      reply_to: reply_to_address
    )
  end

  # Sends notification when a signer declines to sign
  #
  def submission_declined_email(submitter, admin_email:)
    @submitter = submitter
    @submission = submitter.submission
    @template = @submission.template

    mail(
      to: admin_email,
      subject: "⚠️ Document Declined: #{@template.name} by #{@submitter.email}",
      reply_to: reply_to_address
    )
  end

  private

  def download_blob(attachment)
    if attachment.respond_to?(:download)
      attachment.download
    elsif attachment.respond_to?(:blob)
      attachment.blob.download
    else
      attachment.read
    end
  rescue StandardError => e
    Rails.logger.error("[AdminMailer] Failed to download attachment: #{e.message}")
    nil
  end

  def reply_to_address
    ENV.fetch('RESEND_REPLY_TO', ENV.fetch('SUPPORT_EMAIL', nil))
  end
end
