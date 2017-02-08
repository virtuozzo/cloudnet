class AddFailedInBuildToBuildCheckerData < ActiveRecord::Migration
  def change
    add_column :build_checker_data, :failed_in_build, :integer, default: 0
  end
end
