module BuildChecker
  module Logger
    extend ActiveSupport::Concern

    def logger
      self.class.logger
    end

    class_methods do
      def logger
        TaggedLogger.new(::Rails.logger)
      end
    end

    class TaggedLogger < SimpleDelegator
      TAG ||= 'Build Checker'
      TAGGED_METHODS ||= %i(debug info warn error fatal unknown).freeze

      TAGGED_METHODS.each do |method|
        define_method(method) { |msg| Rails.logger.tagged(TAG) { super(msg) }}
      end
    end
  end
end