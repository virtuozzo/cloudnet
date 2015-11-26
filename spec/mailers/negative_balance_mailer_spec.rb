require "rails_helper"

RSpec.describe NegativeBalanceMailer, :type => :mailer do

  describe "shutdown_warning_email_to_user" do
    let(:user) { FactoryGirl.create(:user, notif_delivered: 1) }
    let(:mail) { NegativeBalanceMailer.shutdown_warning_email_to_user(user) }
    let(:from) { Mail::Address.new(ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: negative balance - shutdown warning")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([from.address])
    end
    
    context "rendering" do
      before(:each) do
        send_mail :shutdown_warning_email_to_user, user
      end
      
      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end
    
      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match(CGI.escapeHTML(user.full_name))
        expect(response).to match("This is your 2nd warning")
        expect(response).to include("Your Cloud.net account balance is currently negative by #{balance}")
        expect(response).to match("we will shutdown all your servers after #{user.notif_before_shutdown} warnings")
      end
    end
  end
  
  describe "shutdown_action_email_to_user" do
    let(:user) { FactoryGirl.create(:user, notif_delivered: 10) }
    let(:mail) { NegativeBalanceMailer.shutdown_action_email_to_user(user) }
    let(:from) { Mail::Address.new(ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: negative balance - all your servers shut down")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([from.address])
    end
    
    context "rendering" do
      before(:each) do
        send_mail :shutdown_action_email_to_user, user
      end
      
      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end
    
      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match(CGI.escapeHTML(user.full_name))
        expect(response).to match("This is your 11th warning")
        expect(response).to include("Your Cloud.net account balance is currently negative by #{balance}")
        expect(response).to match("have been shut down")
        expect(response).to match("destroy them after #{user.notif_before_destroy} warnings")
      end
    end
  end
  
  describe "destroy_warning_email_to_user" do
    let(:user) { FactoryGirl.create(:user, notif_delivered: 11) }
    let(:mail) { NegativeBalanceMailer.destroy_warning_email_to_user(user) }
    let(:from) { Mail::Address.new(ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: negative balance - DESTROY warning!")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([from.address])
    end
    
    context "rendering" do
      before(:each) do
        send_mail :destroy_warning_email_to_user, user
      end
      
      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end
    
      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match(CGI.escapeHTML(user.full_name))
        expect(response).to match("This is your 12th warning")
        expect(response).to include("Your Cloud.net account balance is currently negative by #{balance}")
        expect(response).to match("we will DESTROY all your servers automatically after #{user.notif_before_destroy} warnings")
      end
    end
  end
  
  describe "destroy_action_email_to_user" do
    let(:user) { FactoryGirl.create(:user, notif_delivered: 10) }
    let(:mail) { NegativeBalanceMailer.destroy_action_email_to_user(user) }
    let(:from) { Mail::Address.new(ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: negative balance - servers destroyed")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([from.address])
    end
    
    context "rendering" do
      before(:each) do
        send_mail :destroy_action_email_to_user, user
      end
      
      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end
    
      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match(CGI.escapeHTML(user.full_name))
        expect(response).to match("already 10 warning emails")
        expect(response).to include("Your Cloud.net account balance is currently negative by #{balance}")
        expect(response).to match("servers have been destroyed automatically")
      end
    end
  end
end
