module Rekiq
  module Validator
    module ClassMethods
      attr_accessor :for_validation

      def validate(attribute_name, type, options = {})
        options[:allow_nil] = true if options[:allow_nil].nil?

        self.for_validation << {
            attribute_name: attribute_name,
            type:    type,
            options: options
          }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.for_validation = []
    end

    NUMERIC_OPTIONS = {
        greater_than_or_equal_to: :>=
      }

    def validate!
      self.class.for_validation.each do |v|
        attribute_name = v[:attribute_name]
        type    = v[:type]
        options = v[:options]
        value   = send(attribute_name)

        unless options[:allow_nil] and send(attribute_name).nil?
          send("validate_#{type}!", attribute_name, value, options)
        end
      end
    end

    def validate_numeric!(attribute_name, value, options)
      unless value.is_a?(Numeric)
        raise InvalidAttributeValue, "#{attribute_name} must be numeric"
      end

      options.each do |key, option_value|
        if NUMERIC_OPTIONS.key?(key) and
           !value.send(NUMERIC_OPTIONS[key], option_value)
          raise InvalidAttributeValue, "#{attribute_name} must be greater " \
                                       'or equal to 0'
        end
      end
    end

    def validate_bool!(attribute_name, value, options)
      unless [true, false].include?(value)
        raise InvalidAttributeValue, "#{attribute_name} must be either true " \
                                     'or false'
      end
    end
  end
end