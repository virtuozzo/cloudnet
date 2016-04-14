require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe NegativeBalanceChecker do
  let(:scope) {NegativeBalanceChecker.new}

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "enque job for check no paying customers" do
      expect {
        NegativeBalanceChecker.perform_async(5)
      }.to change(NegativeBalanceChecker.jobs, :size).by(1)
    end
  end
  
  context "perform jobs" do
    let!(:user1) { FactoryGirl.create(:user) }
    let!(:user2) { FactoryGirl.create(:user) }
    let!(:suspended_user) { FactoryGirl.create(:user, suspended: true) }
    let(:invoice) {FactoryGirl.create :invoice}
    let!(:server1) {FactoryGirl.create :server, user: user1}
    let(:mailer_q) {ActionMailer::Base.deliveries}
    
    before(:each) do
      mailer_q.clear
      item1 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: 100_000)
      item2 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: 34_000)
      invoice.invoice_items << [item1, item2]
      user1.account = invoice.account
      user1.save
    end

    it "performs actions on all but suspended users" do
      expect(scope).to receive(:check_user).with(user1)
      expect(scope).to receive(:check_user).with(user2)
      expect(scope).not_to receive(:check_user).with(suspended_user)
      scope.perform
    end
    
    it "calls proper actions for users" do
      expect(user1).to receive(:act_for_negative_balance)
      expect(user2).to receive(:clear_unpaid_notifications)
      scope.check_user(user1)
      scope.check_user(user2)
    end
    
    context "integration tests for actions" do
      let(:r_not_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT}
      let(:r_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_SENT_NOT_CONFIRMED}
      let(:r_sent_conf) {RequestForServerDestroyEmailToAdmin::REQUEST_SENT_CONFIRMED}
      
      def action_double(klass)
        action = instance_double(klass)
        allow(klass).to receive(:new).and_return(action)
        expect(action).to receive(:perform)
      end
      
      it "should perform before shutdown" do
        expect {scope.check_user(user1)}.to change {user1.notif_delivered}.by(1)
        expect(mailer_q.count).to eq 1
        mail = mailer_q.first
        expect(mail.subject).to match "shutdown warning"
        expect(mail.to).to eq [user1.email]
      end
      
      it "should perform shutdown" do
        action_double(ShutdownAllServers)
        user1.update_attribute(:notif_delivered, user1.notif_before_shutdown)
        
        expect {scope.check_user(user1)}.to change {user1.notif_delivered}.by(1)
        expect(mailer_q.count).to eq 2
        mail_user = mailer_q.first
        mail_admin = mailer_q.second
        expect(mail_user.subject).to match "all your servers shut down"
        expect(mail_user.to).to eq [user1.email]
        expect(mail_admin.subject).to match "Automatic shutdown - #{user1.full_name}"
        expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      end
      
      it "should perform before destroy - more than 2 days to destroy" do
        action_double(ShutdownAllServers)
        user1.update_attribute(:notif_delivered, user1.notif_before_shutdown + 1)
        
        expect {scope.check_user(user1)}.to change {user1.notif_delivered}.by(1)
        expect(mailer_q.count).to eq 1
        mail_user = mailer_q.first
        expect(mail_user.subject).to match "DESTROY warning"
        expect(mail_user.to).to eq [user1.email]
      end
      
      it "should perform before destroy - 2 days to destroy" do
        action_double(ShutdownAllServers)
        user1.update_attribute(:notif_delivered, user1.notif_before_destroy - 1)
        
        expect {scope.check_user(user1)}.to change {user1.notif_delivered}.by(1)
        expect(mailer_q.count).to eq 2
        mail_user = mailer_q.first
        mail_admin = mailer_q.second
        expect(mail_user.subject).to match "DESTROY warning"
        expect(mail_user.to).to eq [user1.email]
        expect(mail_admin.subject).to match "DESTROY warning! - #{user1.full_name}"
        expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      end
      
      it "should perform admin_acknowledge" do
        user1.update_attribute(:notif_delivered, user1.notif_before_destroy)
        
        expect(user1.admin_destroy_request).to eq r_not_sent
        expect {scope.check_user(user1)}.not_to change {user1.notif_delivered}
        expect(user1.admin_destroy_request).to eq r_sent
        expect(mailer_q.count).to eq 1
        mail_admin = mailer_q.first
        expect(mail_admin.subject).to match "DESTROY request! - #{user1.full_name}"
        expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      end
      
      it "should perform destroy" do
        action_double(DestroyAllServersConfirmed)
        user1.update_attribute(:notif_delivered, user1.notif_before_destroy)
        user1.update_attribute(:admin_destroy_request, r_sent_conf)
        
        scope.check_user(user1)
        
        expect(user1.notif_delivered).to eq 0
        expect(mailer_q.count).to eq 2
        mail_user = mailer_q.first
        mail_admin = mailer_q.second
        expect(mail_user.subject).to match "servers destroyed"
        expect(mail_user.to).to eq [user1.email]
        expect(mail_admin.subject).to match "Automatic destroy - #{user1.full_name}"
        expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      end
      
      it "should clear notifications after payment" do
        user1.update_attribute(:notif_delivered, user1.notif_before_destroy)
        user1.update_attribute(:admin_destroy_request, r_sent_conf)
        FactoryGirl.create :charge, invoice: invoice, amount: 134_000
        
        expect(DestroyAllServersConfirmed).not_to receive(:new)
        scope.check_user(user1)
        
        expect(user1.notif_delivered).to eq 0
        expect(mailer_q.count).to eq 0
        expect(user1.admin_destroy_request).to eq r_not_sent
      end
      
      it "should clear notifications after servers destroyed" do
        user1.update_attribute(:notif_delivered, user1.notif_before_destroy)
        user1.update_attribute(:admin_destroy_request, r_sent_conf)
        user1.servers.destroy_all
        
        expect(DestroyAllServersConfirmed).not_to receive(:new)
        scope.check_user(user1)
        
        expect(user1.notif_delivered).to eq 0
        expect(mailer_q.count).to eq 0
        expect(user1.admin_destroy_request).to eq r_not_sent
      end
    end
  end
end
