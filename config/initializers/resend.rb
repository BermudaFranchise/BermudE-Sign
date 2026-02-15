# frozen_string_literal: true

# =============================================================================
# Resend Email Configuration
# =============================================================================
#
# When RESEND_API_KEY is set, all outgoing emails are sent via Resend API.
# When not set, falls back to existing SMTP configuration.
#
# ENV VARS:
#   RESEND_API_KEY          — Your Resend API key (re_xxxxxxxx)
#   RESEND_FROM_EMAIL       — Default from address (e.g. "SignSuite <noreply@signsuite.live>")
#   RESEND_REPLY_TO         — Default reply-to address (optional)
#
# Resend Setup:
#   1. Create account at resend.com
#   2. Add and verify your domain (signsuite.live or bermude-sign domain)
#   3. Create an API key
#   4. Set RESEND_API_KEY in Railway environment variables
#
require_relative '../../lib/resend_delivery_method'

if ENV['RESEND_API_KEY'].present?
  Rails.application.config.action_mailer.delivery_method = :resend
  Rails.application.config.action_mailer.resend_settings = {
    api_key: ENV['RESEND_API_KEY']
  }

  # Set default from address if configured
  if ENV['RESEND_FROM_EMAIL'].present?
    Rails.application.config.action_mailer.default_options = {
      from: ENV['RESEND_FROM_EMAIL']
    }
  end

  Rails.logger.info('[Resend] Email delivery configured via Resend API') if defined?(Rails.logger) && Rails.logger
end
