# frozen_string_literal: true

boolean = ActiveModel::Type::Boolean.new

# disable in test environment by default
Rack::Attack.enabled = boolean.cast(ENV.fetch('RACK_ATTACK_ENABLED', !Rails.env.test?))

# dedicated cache store
if boolean.cast(ENV.fetch('RACK_ATTACK_CACHE', nil))
  Rack::Attack.cache.store = ActiveSupport::Cache::MemCacheStore.new(ENV.fetch('RACK_ATTACK_CACHE', nil))
end

# Safelist OKD cluster
Rack::Attack.safelist_ip('10.138.5.0/24')

Rack::Attack.throttled_response_retry_after_header = true

#
# Safelist IPs
#
if boolean.cast(ENV.fetch('SAFELIST_ENABLED', nil))
  ENV.fetch('SAFELIST_IP').split(',').each do |addr|
    Rack::Attack.safelist_ip(addr)

    Rails.logger.info('RACK ATTACK') { "Safelisting IP: #{addr}" }
  end
end

#
# Block IPs
#
if boolean.cast(ENV.fetch('BLOCKLIST_ENABLED', nil))
  ENV.fetch('BLOCKLIST_IP').split(',').each do |addr|
    Rack::Attack.blocklist_ip(addr)

    Rails.logger.info('RACK ATTACK') { "Blocking IP: #{addr}" }
  end
end

#
# Throttle requests by IP
#
skip_pattern = Regexp.new('\A/(assets|favicon)/')

if boolean.cast(ENV.fetch('THROTTLE_REQUESTS_ENABLED', nil))
  #
  # Requests by IP
  #
  limit, period = ENV.fetch('THROTTLE_REQUESTS_BY_IP', '10,5').split(',').map(&:to_i)

  throttle = Rack::Attack.throttle('requests by IP', limit:, period:) do |request|
    request.ip unless skip_pattern.match?(request.path)
  end

  Rails.logger.info('RACK ATTACK') do
    "Throttling #{throttle.name}: max #{throttle.limit} requests every #{throttle.period} second(s)"
  end

  #
  # Subnet 1 - 255.255.255.0 subnet mask, effectively
  #
  limit, period = ENV.fetch('THROTTLE_REQUESTS_SUBNET1', '100,10').split(',').map(&:to_i)

  throttle = Rack::Attack.throttle('subnet 1', limit:, period:) do |request|
    request.ip.sub(/\.\d+\z/, '.0') unless skip_pattern.match?(request.path)
  end

  Rails.logger.info('RACK ATTACK') do
    "Throttling #{throttle.name}: max #{throttle.limit} requests every #{throttle.period} second(s)"
  end

  #
  # Subnet 2 - 255.255.0.0 subnet mask, effectively
  #
  limit, period = ENV.fetch('THROTTLE_REQUESTS_SUBNET2', '1000,20').split(',').map(&:to_i)

  throttle = Rack::Attack.throttle('subnet 2', limit:, period:) do |request|
    request.ip.sub(/\.\d+\.\d+\z/, '.0.0') unless skip_pattern.match?(request.path)
  end

  Rails.logger.info('RACK ATTACK') do
    "Throttling #{throttle.name}: max #{throttle.limit} requests every #{throttle.period} second(s)"
  end

  #
  # Total requests
  #
  # This is based on bechmarking roughly 220-240 rps.
  #
  limit, period = ENV.fetch('THROTTLE_REQUESTS_TOTAL', '1000,5').split(',').map(&:to_i)

  throttle = Rack::Attack.throttle('total requests', limit:, period:) do |request|
    '0.0.0.0' unless skip_pattern.match?(request.path)
  end

  Rails.logger.info('RACK ATTACK') do
    "Throttling #{throttle.name}: max #{throttle.limit} requests every #{throttle.period} second(s)"
  end
end

#
# Logging
#
if Rack::Attack.enabled
  Rails.logger.info('RACK ATTACK') { 'rack-attack is enabled.' }

  subscriber = lambda do |*args|
    notification = ActiveSupport::Notifications::Event.new(*args)
    request = notification.payload[:request]

    return unless request.env['rack.attack.matched']

    rack_attack_info = request.env.select { |key, _val| key.start_with?('rack.attack.') }
    request_info = %w[request_method path query_string referer user_agent].index_with { |meth| request.send(meth) }
    request_info.merge! rack_attack_info

    Rails.logger.info('RACK ATTACK') { request_info.inspect.to_s }
  end

  ActiveSupport::Notifications.subscribe(/rack_attack/, subscriber)
else
  Rails.logger.warn('RACK ATTACK') { 'rack-attack is disabled.' }
end
