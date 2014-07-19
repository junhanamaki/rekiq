module Rekiq
  class StandardError < ::StandardError; end
  class SidekiqNotLoaded < StandardError; end
  class InvalidConf < StandardError; end
end