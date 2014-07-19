require 'rekiq/version'
require 'rekiq/exceptions'

unless defined?(Sidekiq)
  raise Rekiq::SidekiqNotLoaded,
        'sidekiq must be required before requiring rekiq'
end

require 'rekiq/middleware/work_overseer'
require 'rekiq/middleware/utils'
require 'rekiq/worker'

module Rekiq

end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Rekiq::Middleware::Utils
    chain.add Rekiq::Middleware::WorkOverseer
  end
end