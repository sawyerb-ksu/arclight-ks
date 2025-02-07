# frozen_string_literal: true

workers ENV.fetch('WEB_CONCURRENCY', 2)
preload_app!
bind format('tcp://0.0.0.0:%s', ENV.fetch('RAILS_PORT', 3000))

# Require token for control app in production
if ENV['PUMA_CONTROL_APP_TOKEN']
  activate_control_app format('tcp://0.0.0.0:%s', ENV.fetch('PUMA_CONTROL_APP_PORT', nil)),
                       { token: ENV['PUMA_CONTROL_APP_TOKEN'] }
end
