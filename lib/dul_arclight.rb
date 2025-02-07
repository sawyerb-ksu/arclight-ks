# frozen_string_literal: true

# Sets up application-level attributes read from environment variables
module DulArclight
  # The value used to authenticate the webhook
  # (not a repo deploy token)
  mattr_accessor :gitlab_token do
    ENV.fetch('GITLAB_TOKEN', nil)
  end

  mattr_accessor :finding_aid_data do
    ENV.fetch('FINDING_AID_DATA', nil) # Set in Dockerfile
  end

  mattr_accessor :matomo_analytics_debug do
    ENV.fetch('MATOMO_ANALYTICS_DEBUG', nil)
  end

  mattr_accessor :matomo_analytics_host do
    ENV.fetch('MATOMO_ANALYTICS_HOST', nil)
  end

  mattr_accessor :matomo_analytics_site_id do
    ENV.fetch('MATOMO_ANALYTICS_SITE_ID', nil)
  end
end
