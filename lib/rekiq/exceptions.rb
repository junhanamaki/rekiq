module Rekiq
  class StandardError < ::StandardError; end
  class SidekiqNotLoaded < StandardError; end
  class InvalidAttributeValue < StandardError; end
end