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
        li "Build Checker status: #{BuildChecker.running? ? 'Active' : 'Stopped'}"
        li "Number of templates for check: #{Template.where(build_checker: true).count}"
        li "Number of locations with templates for test: #{}"
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

end