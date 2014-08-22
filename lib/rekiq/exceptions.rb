module Rekiq
  class StandardError < ::StandardError; end
  class SidekiqNotLoaded < StandardError; end
  class InvalidAttributeValue < StandardError; end
  class CancelMethodMissing < StandardError; end
  class CancelMethodInvocationError < StandardError; end
end