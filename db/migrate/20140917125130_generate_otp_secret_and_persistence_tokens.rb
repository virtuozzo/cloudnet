class GenerateOtpSecretAndPersistenceTokens < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        User.all.each do |user|
          if user.otp_recovery_secret.nil?
            user.send(:generate_otp_auth_secret)
            user.send(:reset_otp_persistence)
            user.save
          end
        end
      end
    end
  end
end
