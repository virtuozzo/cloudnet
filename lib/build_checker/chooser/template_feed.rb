module BuildChecker
  module Chooser
    class TemplateFeed < BaseFeed
      attr_reader :wait_time # in seconds - how long wait for template to be ready for next build

      def initialize(location_id, time_gap_for_same_template = 24.hours)
        @location_id = location_id
        @time_gap_for_same_template = time_gap_for_same_template
      end

      # returns template_id to be scheduled for next test build
      # returns nil if template time gap for choosen template did not passed yet
      def template_id_for_test
        if not_tested_yet_template_ids.any?
          # templates were never checked in the past. Order is not important.
          not_tested_yet_template_ids.first
        elsif recent_template_tests.any?
          # all templates to be scheduled were tested in the past
          # return farthest tested in time template_id
          farthest_tested_template_id
        end
      end

      def not_tested_yet_template_ids
        @not_tested_yet_template_ids ||= to_be_scheduled_template_ids - recent_template_tests.map(&:template_id)
      end

      def recent_template_tests
        @recent_template_tests ||= recent_tests(:template_id)
      end

      def farthest_tested_template_id
        result = farthest_recent_template_test
        start_time = result.build_start || result.start_after

        if ((Time.now - start_time).to_f / @time_gap_for_same_template) < 1
          set_wait_time(start_time)
          nil
        else
          result.template_id
        end
      end

      def farthest_recent_template_test
        recent_template_tests.sort_by { |result| result.build_start || result.start_after }.first
      end

      def set_wait_time(from_time)
        @wait_time = (@time_gap_for_same_template - (Time.now - from_time)).round
      end
    end
  end
end