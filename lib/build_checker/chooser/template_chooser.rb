module BuildChecker
  module Chooser
    class TemplateChooser
      attr_reader :wait_time
      attr_accessor :time_gap_for_same_template, :time_gap_for_same_location

      def self.config
        chooser = new
        yield(chooser)
        chooser
      end

      def initialize
        @time_gap_for_same_template = 24.hours
        @time_gap_for_same_location = 1.minute
      end

      # TODO: return template_id with wait_time for pro-active scheduling
      # For now returns template_id available for immediate test
      def next_template_id
        @template_id = nil
        location_ids.each { |lid| break if @template_id = template_id(lid) }
        @template_id
      end

      def location_ids
        LocationFeed.new(@time_gap_for_same_location).sorted_locations_ids_for_test
      end

      def template_id(location_id)
        TemplateFeed.new(location_id, @time_gap_for_same_template).template_id_for_test
      end
    end
  end
end