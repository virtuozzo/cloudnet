ActiveAdmin.register BuildChecker::Data::BuildCheckerDatum, as: "BuildChecker" do
  actions :all, :except => [:edit, :new]

  action_item :start do
    link_to 'Start build checker', build_checker_path, method: :post
  end

  action_item :stop do
    link_to 'Stop build checker', build_checker_path, method: :delete
  end

  remove_filter :template, :error, :created_at, :updated_at

  index do
    panel "Build checker daemon status" do
      ul do
        li "Server time: #{Time.now}"
        li "Build Checker status: #{BuildChecker.running? ? (BuildChecker.stopping? ? 'Stopping' : 'Active') : 'Stopped'}"
        li "Number of templates for check: #{Template.where(build_checker: true).count}"
        li "Number of active tests: #{BuildChecker.number_of_processed_tasks}"
        li "Number of locations with templates for test: #{}"
        li do
          columns do
            column do
              span "Maximum concurrent builds (recommended 2):"
              span "#{BuildChecker.concurrent_builds}", id: 'concurrentBuildsValue'
              br
              span "Maximum scheduling queue (recommended 2):"
              span "#{BuildChecker.queue_size}", id: 'queueSizeValue'
              br
              span "Min time before scheduling same template (hours):"
              span "#{BuildChecker.same_template_gap}", id: 'sameTemplateValue'
            end
            column span: 3 do
              input type: 'hidden', name: 'serverConcurrentBuilds', value: BuildChecker.concurrent_builds
              input type: 'range', name: 'concurrentBuilds',
                min: 0, max: 5, value: BuildChecker.concurrent_builds
              br
              input type: 'hidden', name: 'serverQueueSize', value: BuildChecker.queue_size
              input type: 'range', name: 'queueSize',
                min: 0, max: 5, value: BuildChecker.queue_size
              br
              input type: 'hidden', name: 'serverSameTemplate', value: BuildChecker.same_template_gap
              input type: 'range', name: 'sameTemplate',
                min: 1, max: 24, value: BuildChecker.same_template_gap
            end
          end
        end
      end
    end

    column :id
    column :template_id
    column :location_id
    column :state
    column :build_result
    column :build_start
    column :build_end
    column :delete_queued_at
    column :deleted_at
    column :onapp_identifier
    column :error

    actions
  end

  collection_action :concurrent_builds, method: :post do
    BuildChecker.concurrent_builds = params['value']
    render json: {serverValue: BuildChecker.concurrent_builds}
  end

  collection_action :queue_size, method: :post do
    BuildChecker.queue_size = params['value']
    render json: {serverValue: BuildChecker.queue_size}
  end

  collection_action :same_template_gap, method: :post do
    BuildChecker.same_template_gap = params['value']
    render json: {serverValue: BuildChecker.same_template_gap}
  end
end