require 'rekiq/version'
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