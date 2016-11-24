module BuildChecker
  module Chooser
    class LocationFeed < BaseFeed
      attr_reader :wait_time

      def initialize(time_gap_for_same_location = 30.seconds)
        @time_gap_for_same_location = time_gap_for_same_location
      end

      def sorted_locations_ids_for_test
        if not_tested_yet_location_ids.any?
          # locations were never checked in the past. Order is not important.
          not_tested_yet_location_ids
        elsif recent_locations_tests.any?
          # all locations to be scheduled were tested in the past
          # prepare location_ids from farthest tested in time
          sorted_tests.map(&:location_id)
        else
          []
        end
      end


      def not_tested_yet_location_ids
        @not_tested_yet_location_ids ||= to_be_scheduled_location_ids - recent_locations_tests.map(&:location_id)
      end

      def recent_locations_tests
        @recent_locations_tests ||= recent_tests(:location_id)
      end

      def to_be_scheduled_location_ids
        location_ids_with_templates - location_ids_in_schedule_queue
      end

      def location_ids_with_templates
        Location.joins(:templates).
          where('templates.id' => to_be_scheduled_template_ids).distinct.ids
      end

      def location_ids_in_schedule_queue
        @locations_ids_in_schedule_queue ||=
          BuildCheckerDatum.select(:location_id).where(scheduled: true).distinct.pluck(:location_id)
      end

      def sorted_tests
        @sorted_tests ||= tests_in_locations_ready_for_next_build.sort_by {|result| result.start_after }
      end

      def tests_in_locations_ready_for_next_build
        recent_locations_tests.select do |result|
          start_time = result.build_start || result.start_after
          if location_ids_in_schedule_queue.include? result.location_id
            false
          elsif ((Time.now - start_time).to_f / @time_gap_for_same_location) < 1
            set_wait_time(start_time)
            false
          else
            true
          end
        end
      end

      def set_wait_time(from_time)
        wait_time = (@time_gap_for_same_location - (Time.now - from_time)).round
        @wait_time = wait_time if @wait_time.nil? || @wait_time > wait_time
      end
    end
  end
end