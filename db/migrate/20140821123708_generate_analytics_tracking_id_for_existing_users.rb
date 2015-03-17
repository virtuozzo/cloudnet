class GenerateAnalyticsTrackingIdForExistingUsers < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up { User.find_each { |u| u.send(:track_analytics) } }
    end
  end
end
