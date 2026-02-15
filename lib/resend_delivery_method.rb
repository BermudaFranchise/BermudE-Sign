# frozen_string_literal: true

# =============================================================================
# ResendDeliveryMethod — ActionMailer delivery method using Resend API
# =============================================================================
#
# Sends emails via Resend's HTTP API instead of SMTP. Supports:
#   - HTML and plain text bodies
#   - File attachments (base64 encoded)
#   - Reply-to headers
#   - CC/BCC
#   - Custom headers
#
# Configuration:
#   config.action_mailer.delivery_method = :resend
#   config.action_mailer.resend_settings = { api_key: ENV['RESEND_API_KEY'] }
#
# Or set RESEND_API_KEY env var.
#
require 'net/http'
require 'json'
require 'base64'

module Mail
  class ResendDeliveryMethod
    RESEND_API_URL = 'https://api.resend.com/emails'

    attr_reader :settings

    def initialize(settings = {})
      @settings = settings
    end

    def deliver!(mail)
      api_key = settings[:api_key] || ENV['RESEND_API_KEY']
      raise ArgumentError, 'Resend API key not configured. Set RESEND_API_KEY env var.' unless api_key

      payload = build_payload(mail)

      uri = URI(RESEND_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{api_key}"
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_body = begin
          JSON.parse(response.body)
        rescue StandardError
          { 'message' => response.body }
        end
        Rails.logger.error("[Resend] Email delivery failed: #{response.code} — #{error_body}")
        raise "Resend API error (#{response.code}): #{error_body['message'] || error_body}"
      end

      result = JSON.parse(response.body)
      Rails.logger.info("[Resend] Email sent successfully: #{result['id']} to #{mail.to}")
      result
    end

    private

    def build_payload(mail)
      payload = {
        from: format_address(mail.from),
        to: Array(mail.to),
        subject: mail.subject
      }

      # HTML and text bodies
      if mail.html_part
        payload[:html] = mail.html_part.body.decoded
      elsif mail.content_type&.include?('text/html')
        payload[:html] = mail.body.decoded
      end

      if mail.text_part
        payload[:text] = mail.text_part.body.decoded
      elsif !payload[:html] && mail.body.present?
        payload[:text] = mail.body.decoded
      end

      # CC / BCC
      payload[:cc] = Array(mail.cc) if mail.cc.present?
      payload[:bcc] = Array(mail.bcc) if mail.bcc.present?

      # Reply-To
      payload[:reply_to] = format_address(mail.reply_to) if mail.reply_to.present?

      # Custom headers
      custom_headers = {}
      mail.header_fields.each do |field|
        next if %w[from to cc bcc subject reply-to content-type mime-version date message-id].include?(field.name.downcase)

        custom_headers[field.name] = field.value if field.name.start_with?('X-')
      end
      payload[:headers] = custom_headers if custom_headers.any?

      # Attachments
      if mail.attachments.any?
        payload[:attachments] = mail.attachments.map do |attachment|
          {
            filename: attachment.filename,
            content: Base64.strict_encode64(attachment.body.decoded),
            content_type: attachment.mime_type
          }
        end
      end

      payload
    end

    def format_address(addresses)
      addresses = Array(addresses)
      return addresses.first if addresses.length == 1

      addresses
    end
  end
end

# Register the delivery method with ActionMailer
ActionMailer::Base.add_delivery_method :resend, Mail::ResendDeliveryMethod
