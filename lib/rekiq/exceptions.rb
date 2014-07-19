module Rekiq
  class StandardError < ::StandardError; end
  class SidekiqNotLoaded < StandardError; end
end