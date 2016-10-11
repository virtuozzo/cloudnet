# Updates billing plan at Onapp for all users, as per ONAPP_BILLING_PLAN_ID env variable

task update_billing_plan: :environment do
  User.where('onapp_id IS NOT NULL').find_each do |user|
    begin
      p user.email
      UserTasks.new.perform(:update_billing_plan, user.id)
    rescue => e
      p e
      # ErrorLogging.new.track_exception(e, extra: { user: user, source: 'update_billing_plan' })
    end
  end
end
