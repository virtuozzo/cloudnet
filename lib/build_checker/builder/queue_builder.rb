module BuildChecker
  module Builder
    # The purpose is to prepare the queue based on internal logic
    # to prevent overloading server or specific federated location
    class QueueBuilder
      include BuildChecker::Data
      include BuildChecker::Logger
      at_exit do
        #exit! unless BuildChecker.running?
        ActiveRecord::Base.clear_active_connections!
        logger.info "Queue Builder stopped"
      end

      def self.run
        new.run
      end

      def run
        logger.info "Queue Builder started"
        loop { schedule_build if empty_slot? }
      end

      def schedule_build
        return unless template_id_ready?
        insert_into_scheduling_queue
      end

      def template_id_ready?
        @template_id = template_chooser.next_template_id
      end

      def insert_into_scheduling_queue
        logger.debug "Scheduling data: #{schedule_data}"
        BuildCheckerDatum.create(schedule_data)
      end

      def schedule_data
        {
          template_id: @template_id,
          location_id: template.location_id,
          start_after: Time.now, # untill template_chooser returns wait_time
          scheduled: true
        }
      end

      def template
        Template.find(@template_id)
      end

      def template_chooser
        BuildChecker::Chooser::TemplateChooser.config do |chooser|
          chooser.time_gap_for_same_template = BuildChecker.same_template_gap.hours
          chooser.time_gap_for_same_location = 1.minute
        end
      end

      def empty_slot?
        sleep(rand(3..6))
        BuildCheckerDatum.where(scheduled: true).count < BuildChecker.queue_size
      end
    end
  end
end