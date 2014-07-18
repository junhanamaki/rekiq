require 'active_model'

module Rekiq
  class ScheduleFormatValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      unless value.respond_to?(:next_occurrence) and
             value.method(:next_occurrence).arity.abs > 0
        record.errors[attribute] <<
          "invalid value for #{attribute}, value must be an object that " \
          'responds to next_occurrence, and that receives at least one ' \
          'argument of type Time, representing Time from which to calculate ' \
          'next occurrence time'
      end
    end
  end
end