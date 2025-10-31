SecureHeaders::Configuration.default do |config|
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' 'unsafe-inline' https://cdnjs.cloudflare.com https://js.stripe.com),
    style_src: %w('self' 'unsafe-inline' https://fonts.googleapis.com),
    font_src: %w('self' https://fonts.gstatic.com),
    img_src: %w('self' data: https:),
    connect_src: %w('self' *.ecosyste.ms https://api.stripe.com),
    frame_src: %w('self' https://js.stripe.com https://hooks.stripe.com)
  }
end
