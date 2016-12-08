module BuildChecker
  module Data
    class BuildCheckerDatum < ActiveRecord::Base
      belongs_to :template
      belongs_to :location #seems redundant, but helps in queries

      validates :template, :location, presence: true
      validate :proper_location_id
      after_create :check_data_size
      MAX_SUCCESS_DATA_PER_TEMPLATE = 30
      MAX_FAILED_DATA_PER_TEMPLATE = 30

      enum state: {
        scheduled:  0, # default
        building:   1,
        to_monitor: 2,
        monitoring: 3,
        to_clean:   4,
        cleaning:   5,
        finished:   6
      }

      enum build_result: {
        waiting: 0, # default
        success: 1,
        failed:  2
      }

      def build_time
        return false if build_start.nil? || build_end.nil?
        build_end - build_start
      end

      def delete_time
        return false if delete_queued_at.nil? || deleted_at.nil?
        deleted_at - delete_queued_at
      end

      private
        def check_data_size
          remove_old_success_data if success_data_number_exceeded?
          remove_old_failed_data  if failed_data_number_exceeded?
        end

        def proper_location_id
          unless template.try(:location_id) == location_id
            errors.add(:location_id, "is not the same as template's location")
          end
        end

        def remove_old_success_data
          remove_old_data(:success, MAX_SUCCESS_DATA_PER_TEMPLATE)
        end

        def remove_old_failed_data
          remove_old_data(:failed, MAX_FAILED_DATA_PER_TEMPLATE)
        end

        def remove_old_data(result, max_number)
          self.class.where(search_query(result)).order(:created_at)
              .limit(number_of_records(result) - max_number)
              .destroy_all
        end

        def success_data_number_exceeded?
          data_number_exceeded?(:success, MAX_SUCCESS_DATA_PER_TEMPLATE)
        end

        def failed_data_number_exceeded?
          data_number_exceeded?(:failed, MAX_FAILED_DATA_PER_TEMPLATE)
        end

        def data_number_exceeded?(result, max_number)
          number_of_records(result) > max_number
        end

        def number_of_records(result)
          self.class.where(search_query(result)).count
        end

        def search_query(result)
          {
            template_id: self.template_id,
            build_result: BuildCheckerDatum.build_results[result.to_s]
          }
        end
    end
  end
end
