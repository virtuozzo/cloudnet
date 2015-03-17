module ActiveRecord
  module EnumField
    def self.included(base)
      base.send :class_attribute, :enumerated_fields_default_values
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def enum_field(attribute, opts = {})
        allowed_values = opts[:allowed_values] || []
        default        = opts[:default]

        fail "Enum Field '#{ attribute }': the default value must be one of the allowed values" unless allowed_values.include?(default) || default.nil?

        enumerated_fields_default_values ||= {}
        enumerated_fields_default_values[attribute] = opts[:default]

        validates_inclusion_of attribute, in: allowed_values
        before_validation { write_attribute(attribute, default) unless default.nil? || read_attribute(attribute) }

        define_singleton_method attribute.to_s.pluralize do
          allowed_values
        end

        define_method attribute do
          value = read_attribute(__method__)
          value ? value.to_sym : enumerated_fields_default_values[__method__]
          value ? value.to_sym : enumerated_fields_default_values[attribute]
        end

        define_method "#{ attribute }=" do |value|
          write_attribute(__method__.to_s.chop, value.to_s)
        end

        define_method "#{ attribute }_was" do
          changes[__method__.to_s.gsub(/^(.*)_was$/, '\\1')].try(:first).try(:to_sym)
        end

        allowed_values.each do |allowed_value|
          define_method "#{ attribute }_#{ allowed_value }?" do
            send(attribute) == allowed_value.to_sym
          end

          define_method "has_#{ attribute }_#{ allowed_value }?" do
            send(attribute) == allowed_value.to_sym
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::EnumField
