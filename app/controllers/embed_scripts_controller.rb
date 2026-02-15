# frozen_string_literal: true

class EmbedScriptsController < ActionController::Metal
  SCRIPT = <<~JAVASCRIPT.freeze
    // SignSuite embed components
    // Configure via the admin panel or API
    console.log('SignSuite embed components loaded');
  JAVASCRIPT

  def show
    headers['Content-Type'] = 'application/javascript'

    self.response_body = SCRIPT

    self.status = 200
  end
end
