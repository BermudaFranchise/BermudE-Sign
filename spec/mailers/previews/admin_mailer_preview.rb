# frozen_string_literal: true

class AdminMailerPreview < ActionMailer::Preview
  def submission_completed_email
    submission = Submission.joins(:submitters)
                          .where.not(submitters: { completed_at: nil })
                          .last

    AdminMailer.submission_completed_email(
      submission,
      recipient_email: 'admin@example.com'
    )
  end

  def invitation_sent_notification
    submitter = Submitter.where.not(email: nil).last

    AdminMailer.invitation_sent_notification(
      submitter,
      admin_email: 'admin@example.com'
    )
  end

  def submission_declined_email
    submitter = Submitter.where.not(email: nil).last

    AdminMailer.submission_declined_email(
      submitter,
      admin_email: 'admin@example.com'
    )
  end
end
