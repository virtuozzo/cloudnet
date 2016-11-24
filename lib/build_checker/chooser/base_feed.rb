module BuildChecker
  module Chooser
    class BaseFeed
      include BuildChecker::Data

      def to_be_scheduled_template_ids
        @to_be_scheduled_template_ids ||= template_ids - already_scheduled_template_ids
      end

      def template_ids
        condition = {build_checker: true}
        condition.merge!({location_id: @location_id}) if @location_id
        Template.where(condition).ids
      end

      def already_scheduled_template_ids
        BuildCheckerDatum.where(scheduled: true).pluck(:template_id)
      end

      def recent_tests(subject)
        BuildCheckerDatum.select("DISTINCT ON (#{subject.to_s}) *").
          order(subject, start_after: :desc).
          where(template_id: to_be_scheduled_template_ids)
      end
    end
  end
end