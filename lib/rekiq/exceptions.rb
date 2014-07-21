module Rekiq
  class StandardError < ::StandardError; end
  class SidekiqNotLoaded < StandardError; end
  class InvalidAttributeValue < StandardError; end
  class CancellerMethodMissing < StandardError; end
end